//
//  Media.m
//  Banyan
//
//  Created by Devang Mundhra on 5/15/13.
//
//

#import "Media.h"
#import "RemoteObject.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SDWebImage/SDWebImageDownloader.h"
#import "UIImage+ResizeAdditions.h"
#import "AFParseAPIClient.h"
#import "BNMisc.h"

@implementation Media

@dynamic createdAt;
@dynamic filename;
@dynamic filesize;
@dynamic height;
@dynamic length;
@dynamic localURL;
@dynamic mediaID;
@dynamic mediaType;
@dynamic orientation;
@dynamic progress;
@dynamic remoteStatusNumber;
@dynamic remoteURL;
@dynamic thumbnail;
@dynamic title;
@dynamic width;
@dynamic remoteObject;

+ (Media *)newMediaForObject:(RemoteObject *)remoteObject
{
    Media *media = [[Media alloc] initWithEntity:[NSEntityDescription entityForName:@"Media"
                                                             inManagedObjectContext:[remoteObject managedObjectContext]]
                  insertIntoManagedObjectContext:[remoteObject managedObjectContext]];
    
    media.remoteObject = remoteObject;
    return media;
}

- (void)cancelUpload
{
    
}

- (void)remove {
    [self cancelUpload];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.localURL error:&error];
    [[self managedObjectContext] deleteObject:self];
    [self save];
}

- (void)save
{
    NSError *error = nil;
    if (![self.managedObjectContext saveToPersistentStore:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@ in saving media", error, [error userInfo]);
        exit(-1);
    }
}

- (void)awakeFromFetch {
    if ((self.remoteStatus == MediaRemoteStatusPushing /*&& _uploadOperation == nil*/) || (self.remoteStatus == MediaRemoteStatusProcessing)) {
        self.remoteStatus = MediaRemoteStatusFailed;
    }
}

- (MediaRemoteStatus)remoteStatus {
    return (MediaRemoteStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(MediaRemoteStatus)aStatus {
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

- (float)progress {
    [self willAccessValueForKey:@"progress"];
    NSNumber *result = [self primitiveValueForKey:@"progress"];
    [self didAccessValueForKey:@"progress"];
    return [result floatValue];
}

- (void)setProgress:(float)progress {
    [self willChangeValueForKey:@"progress"];
    [self setPrimitiveValue:[NSNumber numberWithFloat:progress] forKey:@"progress"];
    [self didChangeValueForKey:@"progress"];
}

- (NSString *)mediaTypeName {
    if ([self.mediaType isEqualToString:@"image"]) {
        return NSLocalizedString(@"Image", @"");
    } else if ([self.mediaType isEqualToString:@"video"]) {
        return NSLocalizedString(@"Video", @"");
    } else if ([self.mediaType isEqualToString:@"audio"]) {
        return NSLocalizedString(@"Audio", @"");
    } else if ([self.mediaType isEqualToString:@"gif"]) {
        return NSLocalizedString(@"Gif", @"");
    } else {
        return self.mediaType;
    }
}

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus {
    switch ([remoteStatus intValue]) {
        case MediaRemoteStatusPushing:
            return NSLocalizedString(@"Uploading", @"");
            break;
        case MediaRemoteStatusFailed:
            return NSLocalizedString(@"Failed", @"");
            break;
        case MediaRemoteStatusSync:
            return NSLocalizedString(@"Uploaded", @"");
            break;
        default:
            return NSLocalizedString(@"Pending", @"");
            break;
    }
}

- (NSString *)remoteStatusText {
    return [Media titleForRemoteStatus:self.remoteStatusNumber];
}

- (void) uploadWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    assert(self.filename.length == 0);
    [self save];
    if (self.remoteStatus == MediaRemoteStatusSync) {
        return;
    }
    
    if ([self.mediaType isEqualToString:@"image"]) {
        [self uploadImageWithSuccess:^{
            successBlock();
            [self save];
        } failure:errorBlock];
    } else if ([self.mediaType isEqualToString:@"audio"]) {
        [self uploadAudioWithSuccess:^{
            successBlock();
            [self save];
        } failure:errorBlock];
    } else if ([self.mediaType isEqualToString:@"gif"]) {
        [self uploadGifWithSuccess:^{
            successBlock();
            [self save];
        } failure:errorBlock];
    }
}


- (void) deleteWitSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))errorBlock
{
    if (!self.filename)
        return;
    
    [[AFParseAPIClient sharedClient] setDefaultHeader:@"X-Parse-Master-Key" value:PARSE_MASTER_KEY];
    [[AFParseAPIClient sharedClient] deletePath:PARSE_API_FILES_URL(self.filename)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                                            self.remoteStatus = MediaRemoteStatusSync;
                                            if (successBlock)
                                                successBlock();
                                        }
                                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//                                            self.remoteStatus = MediaRemoteStatusFailed;
                                            if (errorBlock)
                                                errorBlock(error);
                                        }];
    
    self.remoteObject = nil;
    [self remove];
    
    [[AFParseAPIClient sharedClient] setDefaultHeader:@"X-Parse-Master-Key" value:nil];
}

+ (Media *)getMediaOfType:(NSString *)type inMediaSet:(NSOrderedSet *)mediaSet
{
    Media *mediaToReturn = nil;
    for (Media *media in mediaSet) {
        if ([media.mediaType isEqualToString:type]) {
            mediaToReturn = media;
            break;
        }
    }
    return mediaToReturn;
}

+ (NSOrderedSet *)getAllMediaOfType:(NSString *)type inMediaSet:(NSOrderedSet *)mediaSet
{
    NSMutableOrderedSet *mediaToReturn = [NSMutableOrderedSet orderedSet];
    for (Media *media in mediaSet) {
        if ([media.mediaType isEqualToString:type]) {
            [mediaToReturn insertObject:media atIndex:mediaToReturn.count];
        }
    }
    
    return mediaToReturn.count ? mediaToReturn : nil;
}

# pragma mark Private methods
- (void) uploadAudioWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    self.remoteStatus = MediaRemoteStatusProcessing;
    NSData *audioData = nil;
    PFFile *audioFile = nil;
    audioData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.localURL]];
    audioFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@.caf", [BNMisc genRandStringLength:10]]
                                data:audioData];
    self.remoteStatus = MediaRemoteStatusPushing;
    
    [audioFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            self.remoteURL = audioFile.url;
            self.filename = audioFile.name;
            self.remoteStatus = MediaRemoteStatusSync;
            self.localURL = nil;
            successBlock();
        } else {
            errorBlock(error);
        }
    }];
}

- (void) uploadImageWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    self.remoteStatus = MediaRemoteStatusProcessing;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:[NSURL URLWithString:self.localURL] resultBlock:^(ALAsset *asset) {
        NSData *imageData;
        PFFile *imageFile = nil;
        
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        CGImageRef imageRef = [rep fullScreenImage]; // not fullResolutionImage
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        
        // For now, compress the image before sending.
        // When PUT API is done, compress on the server
        // TODO
        UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:[[UIScreen mainScreen] bounds].size interpolationQuality:kCGInterpolationLow];
        
        imageData = UIImageJPEGRepresentation(resizedImage, 1);
        imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@.jpg", [BNMisc genRandStringLength:10]]
                                    data:imageData];
        self.remoteStatus = MediaRemoteStatusPushing;
        
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                self.remoteURL = imageFile.url;
                self.filename = imageFile.name;
                self.remoteStatus = MediaRemoteStatusSync;
                self.localURL = nil;
                successBlock();
            } else {
                errorBlock(error);
            }
        }];
    }
            failureBlock:^(NSError *error) {
                self.remoteStatus = MediaRemoteStatusFailed;
                errorBlock(error);
            }
     ];
}

- (void) uploadGifWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    self.remoteStatus = MediaRemoteStatusProcessing;
    NSData *gifData = nil;
    PFFile *gifFile = nil;
    gifData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.localURL]];
    gifFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@.gif", [BNMisc genRandStringLength:10]]
                                data:gifData];
    self.remoteStatus = MediaRemoteStatusPushing;
    
    [gifFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            self.remoteURL = gifFile.url;
            self.filename = gifFile.name;
            self.remoteStatus = MediaRemoteStatusSync;
            self.localURL = nil;
            successBlock();
        } else {
            errorBlock(error);
        }
    }];
}

+ (RKEntityMapping *)mediaMappingForRK
{
    RKEntityMapping *mediaMapping = [RKEntityMapping mappingForEntityForName:kBNMediaClassKey
                                                        inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [mediaMapping addAttributeMappingsFromDictionary:@{@"url": @"remoteURL"}];
    [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType"]];
    mediaMapping.identificationAttributes = @[@"filename", @"remoteURL"];
    return mediaMapping;
}

- (void) getImageWithContentMode:(UIViewContentMode)contentMode
                          bounds:(CGSize)size
            interpolationQuality:(CGInterpolationQuality)quality
             forMediaWithSuccess:(void (^)(UIImage *))success
                         failure:(void (^)(NSError *error))failure
{
    [self getImageForMediaWithSuccess:^(UIImage *image) {
        success([image resizedImageWithContentMode:contentMode bounds:size interpolationQuality:quality]);
    }
                              failure:failure];
}

- (void) getImageForMediaWithSuccess:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure
{
    assert([self.mediaType isEqualToString:@"image"]);
    
    if ([self.remoteURL length]) {
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:self.remoteURL] options:SDWebImageDownloaderUseNSURLCache
                                                             progress:nil
                                                            completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                if (image)
                                                                    success(image);
                                                                else
                                                                    if (failure) failure(error);
                                                            }];
    } else if ([self.localURL length]) {
        ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
        [library assetForURL:[NSURL URLWithString:self.localURL] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef imageRef = [rep fullScreenImage];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            success(image);
        }
                failureBlock:^(NSError *error) {
                    NSLog(@"***** ERROR IN FILE CREATE ***\nCan't find the asset library image");
                }
         ];
    }
}


@end

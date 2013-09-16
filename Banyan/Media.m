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
#import "BNAWSS3Client.h"
#import "User.h"

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
    Media *media = [NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:[remoteObject managedObjectContext]];
    
    media.remoteObject = remoteObject;
    media.filename = [BNMisc genRandStringLength:10];
    media.createdAt = [NSDate date];
    media.remoteStatus = MediaRemoteStatusLocal;
//    [media save];
    
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

//- (void)awakeFromFetch {
//    if ((self.remoteStatus == MediaRemoteStatusPushing /*&& _uploadOperation == nil*/) || (self.remoteStatus == MediaRemoteStatusProcessing)) {
//        self.remoteStatus = MediaRemoteStatusFailed;
//    }
//}

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

+ (void) validateAllMedias
{
    // Any objects which are in the Uploading state should be marked as failed
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Media" inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) OR (remoteStatusNumber = %@)",
                              [NSNumber numberWithInt:MediaRemoteStatusPushing], [NSNumber numberWithInt:MediaRemoteStatusProcessing]];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    for (Media *obj in array)
        obj.remoteStatus = MediaRemoteStatusFailed;
}

- (void) uploadWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    if (self.remoteStatus == MediaRemoteStatusSync || self.remoteStatus == MediaRemoteStatusProcessing || self.remoteStatus == MediaRemoteStatusPushing) {
        return;
    }

    NSLog(@"Uploading %@ media (Status: %@, filename: %@) for object id: %@", self.mediaType, self.remoteStatusNumber, self.filename, self.remoteObject.bnObjectId);
    
    void (^success)() = ^(){
        successBlock();
        self.remoteStatus = MediaRemoteStatusSync;
        // Remove the local file
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        [fileManager removeItemAtPath:self.localURL error:&error];
        assert(!error);
        self.localURL = nil;
        [self save];
    };
    
    void (^failure)(NSError *error) = ^(NSError *error){
        errorBlock(error);
        self.remoteStatus = MediaRemoteStatusFailed;
        [self save];
    };
    
    if ([self.mediaType isEqualToString:@"image"]) {
        [self uploadImageWithSuccess:success failure:failure];
    } else if ([self.mediaType isEqualToString:@"audio"]) {
        [self uploadAudioWithSuccess:success failure:failure];
    } else if ([self.mediaType isEqualToString:@"gif"]) {
        [self uploadGifWithSuccess:success failure:failure];
    }
}

- (void) deleteWitSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))errorBlock
{
    if (!self.filename)
        return;
    
    [BNAWSS3Client deleteObjectWithFileName:self.filename inBackgroundWithBlock:^(bool succeeded, NSError *error) {
        if (succeeded)
        {
            if (successBlock) successBlock();
        } else {
            if (errorBlock) errorBlock(error);
        }
    }];
    
    self.remoteObject = nil;
    [self remove];
    
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
    audioData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.localURL]];
    self.remoteStatus = MediaRemoteStatusPushing;
    
    [BNAWSS3Client uploadData:audioData withContentType:@"audio/caf" forFileName:[NSString stringWithFormat:@"%@/%@_%@.caf", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], self.filename]
        inBackgroundWithBlock:^(bool succeeded, NSString *url, NSString *filename, NSError *error) {
            if (succeeded) {
                self.remoteURL = url;
                self.filename = filename;
                successBlock();
            } else {
                errorBlock(error);
            }
        }
     ];
}

- (void) uploadImageWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    self.remoteStatus = MediaRemoteStatusProcessing;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:[NSURL URLWithString:self.localURL] resultBlock:^(ALAsset *asset) {
        NSData *imageData;
        
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        CGImageRef imageRef = [rep fullScreenImage]; // not fullResolutionImage
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        
        // For now, compress the image before sending.
        // When PUT API is done, compress on the server
        // TODO
        UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:[[UIScreen mainScreen] bounds].size interpolationQuality:kCGInterpolationLow];
        
        imageData = UIImageJPEGRepresentation(resizedImage, 1);
        
        self.remoteStatus = MediaRemoteStatusPushing;

        [BNAWSS3Client uploadData:imageData withContentType:@"image/jpeg" forFileName:[NSString stringWithFormat:@"%@/%@_%@.jpg", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], self.filename] inBackgroundWithBlock:^(bool succeeded, NSString *url, NSString *filename, NSError *error) {
            if (succeeded) {
                self.remoteURL = url;
                self.filename = filename;
                successBlock();
            } else {
                errorBlock(error);
            }
        }];
    }
            failureBlock:^(NSError *error) {
                errorBlock(error);
            }
     ];
}

- (void) uploadGifWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    self.remoteStatus = MediaRemoteStatusProcessing;
    NSData *gifData = nil;
    gifData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.localURL]];
    self.remoteStatus = MediaRemoteStatusPushing;
    
    [BNAWSS3Client uploadData:gifData withContentType:@"image/gif" forFileName:[NSString stringWithFormat:@"%@/%@_%@.gif", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], self.filename] inBackgroundWithBlock:^(bool succeeded, NSString *url, NSString *filename, NSError *error) {
        if (succeeded) {
            self.remoteURL = url;
            self.filename = filename;
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
                                                                if (image) {
                                                                    if (success) success(image);
                                                                }
                                                                else {
                                                                    if (failure) failure(error);
                                                                }
                                                            }];
    } else if ([self.localURL length]) {
        ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
        [library assetForURL:[NSURL URLWithString:self.localURL] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef imageRef = [rep fullScreenImage];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            if (success) success(image);
        }
                failureBlock:failure
         ];
    }
}

@end

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
    [self save];
    if (self.remoteStatus == MediaRemoteStatusSync) {
        return;
    }
    
    if ([self.mediaType isEqualToString:@"image"]) {
        [self uploadImageWithSuccess:successBlock failure:errorBlock];
    } else if ([self.mediaType isEqualToString:@"audio"]) {
        [self uploadAudioWithSuccess:successBlock failure:errorBlock];
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
                                            self.remoteStatus = MediaRemoteStatusSync;
                                            if (successBlock)
                                                successBlock();
                                            [self remove];
                                        }
                                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                            self.remoteStatus = MediaRemoteStatusFailed;
                                            if (errorBlock)
                                                errorBlock(error);
                                        }];
    
    [[AFParseAPIClient sharedClient] setDefaultHeader:@"X-Parse-Master-Key" value:nil];
}

+ (Media *)getMediaOfType:(NSString *)type inMediaSet:(NSSet *)mediaSet
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

+ (RKEntityMapping *)mediaMappingForRK
{
    RKEntityMapping *mediaMapping = [RKEntityMapping mappingForEntityForName:kBNMediaClassKey
                                                        inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [mediaMapping addAttributeMappingsFromDictionary:@{@"url": @"remoteURL"}];
    [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType"]];
    mediaMapping.identificationAttributes = @[@"filename", @"remoteURL"];
    return mediaMapping;
}
@end

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
#import "SDWebImage/SDWebImageManager.h"
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
@dynamic mediaType;
@dynamic orientation;
@dynamic progress;
@dynamic remoteStatusNumber;
@dynamic remoteURL;
@dynamic thumbnail;
@dynamic thumbnailURL;
@dynamic title;
@dynamic width;
@dynamic remoteObject;
@dynamic thumbnailfilename;

+ (Media *)newMediaForObject:(RemoteObject *)remoteObject
{
    if (![remoteObject managedObjectContext]) {
        [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Problem in trying to add this media to the %@", [[remoteObject entity].description lowercaseString]]
                                    message:@"Please cancel and try again. Sorry for the inconvenience!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"Error" action:@"No context for new media" label:[remoteObject entity].description value:nil];
        return nil;
    }
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
        BNLogError(@"Unresolved Core Data Save error %@, %@ in saving media", error, [error userInfo]);
        exit(-1);
    }
}

- (void)cloneFrom:(Media *)source
{
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        // Skip filename to avoid getting multiple media object when mapping through restkit identificationAttributes
        if ([key isEqualToString:@"filename"]) {
            BNLogTrace(@"Skipping attribute %@", key);
            continue;
        }
        BNLogTrace(@"Copying attribute %@", key);
        [self setValue:[source valueForKey:key] forKey:key];
    }
    
    for (NSString *key in [[[source entity] relationshipsByName] allKeys]) {
        if ([key isEqualToString:@"remoteObject"]) {
            BNLogTrace(@"Skipping relationship %@", key);
        } else {
            BNLogTrace(@"Copying relationship %@", key);
            [self setValue: [source valueForKey:key] forKey: key];
        }
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
    
    // Delete all media with no remoteObject
    // This usually happens because there can be a mismatch between a GET request coming down from a server while another PUT/POST request is happening.
    // Consider the scenario where a piece with media failed to upload, and the app was closed. On the next open, the stories and pieces will be
    // GET from the backend, while a piece is being uploaded. It can well happen that the piece has been uploaded but the media hasn't been uploaded.
    // Now if the upload of the media happens first, there will be a piece with the media. But later when the backend replies with the piece with
    // an empty media, the media gets disconnected from the remoteObject, and the piece has no media.
    predicate = [NSPredicate predicateWithFormat:@"remoteObject = nil"];
    [request setPredicate:predicate];
    error = nil;
    array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    for (Media *obj in array)
        [obj remove];
}

- (void) uploadWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    if (self.remoteStatus == MediaRemoteStatusSync || self.remoteStatus == MediaRemoteStatusProcessing || self.remoteStatus == MediaRemoteStatusPushing) {
        return;
    }

    BNLogInfo(@"Uploading %@ media (Status: %@, filename: %@) for object id: %@", self.mediaType, self.remoteStatusNumber, self.filename, self.remoteObject.bnObjectId);
    
    void (^success)() = ^(){
        self.remoteStatus = MediaRemoteStatusSync;
        self.localURL = nil;
        [self save];
        successBlock();
    };
    
    void (^failure)(NSError *error) = ^(NSError *error){
        self.remoteStatus = MediaRemoteStatusFailed;
        [self save];
        errorBlock(error);
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
    
    [BNAWSS3Client uploadData:audioData withContentType:@"audio/wav" forFileName:[NSString stringWithFormat:@"%@/%@_%@.wav", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], self.filename]
        inBackgroundWithBlock:^(bool succeeded, NSString *url, NSString *filename, NSError *error) {
            if (succeeded) {
                self.remoteURL = url;
                self.filename = filename;
                
                // Remove the local file
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error = nil;
                if (![fileManager removeItemAtPath:[(NSURL *)[NSURL URLWithString:self.localURL] path] error:&error])
                    BNLogError(@"Error: %@ in deleting file: %@", error.localizedDescription, self.localURL);
                
                successBlock();
            } else {
                errorBlock(error);
            }
        }
     ];
}

- (void) uploadImageWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    if (self.remoteURL.length) {
        // This means the bigger image was uploaded fine but the thumbnail could not be uploaded.
        // Upload only the thumbnail
        [self uploadThumbnailImageWithSuccess:successBlock failure:errorBlock];
        return;
    }
    
    self.remoteStatus = MediaRemoteStatusProcessing;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:[NSURL URLWithString:self.localURL] resultBlock:^(ALAsset *asset) {
        NSData *imageData;
        
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        CGImageRef imageRef = [rep fullScreenImage]; // Not full resolution image
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        
        imageData = UIImageJPEGRepresentation(image, 1);
        
        self.remoteStatus = MediaRemoteStatusPushing;

        [BNAWSS3Client uploadData:imageData withContentType:@"image/jpeg" forFileName:[NSString stringWithFormat:@"%@/%@_%@.jpg", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], self.filename] inBackgroundWithBlock:^(bool succeeded, NSString *url, NSString *filename, NSError *error) {
            if (succeeded) {
                // Cache this in SDWebCache
                [[SDWebImageManager sharedManager].imageCache storeImage:image forKey:url toDisk:YES];
                
                self.remoteURL = url;
                self.filename = filename;
                
                // Bigger image has been successfully uploaded. Upload the thumbnail now
                [self uploadThumbnailImageWithSuccess:successBlock failure:errorBlock];
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

- (void) uploadThumbnailImageWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    if (!self.thumbnail) {
        successBlock();
        return;
    }
    
    [BNAWSS3Client uploadData:UIImageJPEGRepresentation(self.thumbnail, 1) withContentType:@"image/jpeg"
                  forFileName:[NSString stringWithFormat:@"%@/%@_%@_%@.jpg", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], [BNMisc genRandStringLength:10], NSStringFromCGSize(MEDIA_THUMBNAIL_SIZE)]
        inBackgroundWithBlock:^(bool succeeded, NSString *url, NSString *filename, NSError *error) {
            if (succeeded) {
                // Cache this in SDWebCache
                [[SDWebImageManager sharedManager].imageCache storeImage:self.thumbnail forKey:url toDisk:YES];
                
                self.thumbnail = nil;
                self.thumbnailURL = url;
                self.thumbnailfilename = filename;

                successBlock();
            } else {
                errorBlock(error);
            }
        }];
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
            
            // Remove the local file
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error = nil;
            if (![fileManager removeItemAtPath:[(NSURL *)[NSURL URLWithString:self.localURL] path] error:&error])
                BNLogError(@"Error: %@ in deleting file: %@", error.localizedDescription, self.localURL);
            
            successBlock();
        } else {
            errorBlock(error);
        }
    }];
}

+ (RKEntityMapping *)mediaMappingForRKGET
{
    RKEntityMapping *mediaMapping = [RKEntityMapping mappingForEntityForName:kBNMediaClassKey
                                                        inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [mediaMapping addAttributeMappingsFromDictionary:@{@"url": @"remoteURL"}];
    [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType", @"thumbnailURL", @"thumbnailfilename"]];
    mediaMapping.identificationAttributes = @[@"filename", @"remoteURL"];
    return mediaMapping;
}

+ (RKObjectMapping *)mediaRequestMapping
{
    RKObjectMapping *mediaMapping = [RKObjectMapping requestMapping];
    [mediaMapping addAttributeMappingsFromDictionary:@{@"remoteURL": @"url"}];
    [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType", @"thumbnailURL", @"thumbnailfilename"]];
    return mediaMapping;
}


- (void) getImageWithContentMode:(UIViewContentMode)contentMode
                          bounds:(CGSize)size
            interpolationQuality:(CGInterpolationQuality)quality
             forMediaWithSuccess:(void (^)(UIImage *))success
                        progress:(void (^)(NSUInteger receivedSize, long long expectedSize))progress
                         failure:(void (^)(NSError *error))failure
                includeThumbnail:(BOOL) includeThumbnail
{
    [self getImageForMediaWithSuccess:^(UIImage *image) {
        success([image resizedImageWithContentMode:contentMode bounds:size interpolationQuality:quality]);
    }
                             progress:progress
                              failure:failure
                     includeThumbnail:includeThumbnail];
}

- (void) getImageForMediaWithSuccess:(void (^)(UIImage *image))success
                            progress:(void (^)(NSUInteger receivedSize, long long expectedSize))progress
                             failure:(void (^)(NSError *error))failure
                    includeThumbnail:(BOOL) includeThumbnail
{
    assert([self.mediaType isEqualToString:@"image"]);
    
    if (includeThumbnail) {
        UIImage *image = self.thumbnail;
        if (image) {
            success(image);
            return;
        }
    }
    
    if (includeThumbnail && [self.thumbnailURL length]) {
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:self.thumbnailURL]
                                                              options:SDWebImageDownloaderUseNSURLCache
                                                             progress:progress
                                                            completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                if (image) {
                                                                    if (success) success(image);
                                                                }
                                                                else {
                                                                    if (failure) failure(error);
                                                                }
                                                            }];
    } else if ([self.remoteURL length]) {
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:self.remoteURL]
                                                              options:SDWebImageDownloaderUseNSURLCache
                                                             progress:progress
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
            UIImage *image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:(UIImageOrientation)[rep orientation]];
            if (success) success(image);
        }
                failureBlock:failure
         ];
    }
}

@end

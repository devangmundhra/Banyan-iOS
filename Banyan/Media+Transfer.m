//
//  Media+Transfer.m
//  Banyan
//
//  Created by Devang Mundhra on 3/19/14.
//
//

#import "Media+Transfer.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SDWebImage/SDWebImageDownloader.h"
#import "SDWebImage/SDWebImageManager.h"
#import "UIImage+ResizeAdditions.h"
#import "RemoteObject.h"
#import "User.h"
#import "BNS3TransferManager.h"

@implementation Media (Transfer)

- (void)cancelUpload
{
    
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

# pragma mark Private methods
- (void) uploadAudioWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    self.remoteStatus = MediaRemoteStatusProcessing;
    NSData *audioData = nil;
    audioData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.localURL]];
    self.remoteStatus = MediaRemoteStatusPushing;
    
    __weak typeof(self) wself = self;
    NSString *filename = [NSString stringWithFormat:@"%@/%@_%@.wav", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], self.filename];
    [self.transferManager uploadData:audioData withContentType:@"audio/wav"
                         forFileName:filename
                        successBlock:^(NSString *url){
                            wself.remoteURL = url;
                            wself.filename = filename;
                            
                            // Remove the local file
                            NSFileManager *fileManager = [NSFileManager defaultManager];
                            NSError *error = nil;
                            if (![fileManager removeItemAtPath:[(NSURL *)[NSURL URLWithString:wself.localURL] path] error:&error])
                                BNLogError(@"Error: %@ in deleting file: %@", error.localizedDescription, wself.localURL);
                            
                            successBlock();
                        }
                          errorBlock:errorBlock];
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
        self.width = [NSNumber numberWithFloat:image.size.width];
        self.height = [NSNumber numberWithFloat:image.size.height];
        
        imageData = UIImageJPEGRepresentation(image, 1);
        
        self.remoteStatus = MediaRemoteStatusPushing;
        __weak typeof(self) wself = self;
        NSString *filename = [NSString stringWithFormat:@"%@/%@_%@.jpg", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], self.filename];
        [self.transferManager uploadData:imageData withContentType:@"image/jpeg"
                             forFileName:filename
                            successBlock:^(NSString *url) {
                                // Cache this in SDWebCache
                                [[SDWebImageManager sharedManager].imageCache storeImage:image forKey:url toDisk:YES];
                                
                                wself.remoteURL = url;
                                wself.filename = filename;
                                
                                // Bigger image has been successfully uploaded. Upload the thumbnail now
                                [wself uploadThumbnailImageWithSuccess:successBlock failure:errorBlock];
                            }
                              errorBlock:errorBlock];
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
    
    __weak typeof(self) wself = self;
    NSString *filename = [NSString stringWithFormat:@"%@/%@_%@_%@.jpg", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], [BNMisc genRandStringLength:10], NSStringFromCGSize(MEDIA_THUMBNAIL_SIZE)];
    
    [self.transferManager uploadData:UIImageJPEGRepresentation(self.thumbnail, 1)
                     withContentType:@"image/jpeg"
                         forFileName:filename
                        successBlock:^(NSString *url) {
                            // Cache this in SDWebCache
                            [[SDWebImageManager sharedManager].imageCache storeImage:self.thumbnail forKey:url toDisk:YES];
                            
                            wself.thumbnail = nil;
                            wself.thumbnailURL = url;
                            wself.thumbnailfilename = filename;
                            
                            successBlock();
                        }
                          errorBlock:errorBlock];
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

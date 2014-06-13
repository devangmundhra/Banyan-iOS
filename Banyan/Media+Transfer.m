//
//  Media+Transfer.m
//  Banyan
//
//  Created by Devang Mundhra on 3/19/14.
//
//

#import "Media+Transfer.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SDWebImage/SDWebImageManager.h"
#import "UIImage+ResizeAdditions.h"
#import "RemoteObject.h"
#import "User.h"
#import "BNS3TransferManager.h"
#import "MBProgressHUD.H"
#import "BanyanAppDelegate.h"

static char operationKey;

@implementation Media (Transfer)

- (void)cancelUpload
{
    // Cancel in progress upload
    BNS3PutObjectRequest *operation = objc_getAssociatedObject(self, &operationKey);
    if (operation)
    {
        [operation cancel];
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void) uploadWithSuccess:(void (^)())successBlock progress:(void (^)(float progressPct, long long totalBytes))progressBlock failure:(void (^)(NSError *error))errorBlock
{
    if (self.remoteStatus == MediaRemoteStatusSync || self.remoteStatus == MediaRemoteStatusProcessing || self.remoteStatus == MediaRemoteStatusPushing) {
        return;
    }
    
    BNLogInfo(@"Uploading %@ media (Status: %@, filename: %@) for object id: %@", self.mediaType, self.remoteStatusNumber, self.filename, self.remoteObject.bnObjectId);
    
    void (^success)() = ^(){
        self.remoteStatus = MediaRemoteStatusSync;
        self.localURL = nil;
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self save];
        if (successBlock) successBlock();
    };
    
    void (^progress)(float progressPct, long long totalBytes) = ^(float progressPct, long long totalBytes) {
        self.progress = progressPct;
        if (progressBlock) progressBlock(progressPct, totalBytes);
    };
    
    void (^failure)(NSError *error) = ^(NSError *error) {
        self.remoteStatus = MediaRemoteStatusFailed;
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self save];
        if (errorBlock) errorBlock(error);
    };
    
    if ([self.mediaType isEqualToString:@"image"]) {
        [self uploadImageWithSuccess:success progress:progress failure:failure];
    } else if ([self.mediaType isEqualToString:@"audio"]) {
        [self uploadAudioWithSuccess:success progress:progress failure:failure];
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
            [BNMisc sendGoogleAnalyticsError:error inAction:@"deleting media" isFatal:NO];
            if (errorBlock) errorBlock(error);
        }
    }];
    
    if (!self.thumbnailfilename)
        return;
    [BNAWSS3Client deleteObjectWithFileName:self.thumbnailfilename inBackgroundWithBlock:^(bool succeeded, NSError *error) {
        if (!succeeded) {
            [BNMisc sendGoogleAnalyticsError:error inAction:@"deleting thumbnail of media" isFatal:NO];
        }
    }];
}

# pragma mark Private methods
- (void) uploadAudioWithSuccess:(void (^)())successBlock progress:(void (^)(float progress, long long totalBytes))progressBlock failure:(void (^)(NSError *error))errorBlock
{
    self.remoteStatus = MediaRemoteStatusProcessing;
    NSData *audioData = nil;
    audioData = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.localURL]];
    self.filesize = [NSNumber numberWithUnsignedInteger:audioData.length];
    self.remoteStatus = MediaRemoteStatusPushing;
    
    __weak typeof(self) wself = self;
    NSString *filename = [NSString stringWithFormat:@"%@/%@_%@.wav", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], self.filename];
    S3TransferOperation *operation =[self.remoteObject.transferManager uploadData:audioData withContentType:@"audio/wav"
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
                                                                    progressBlock:progressBlock
                                                                       errorBlock:errorBlock];
    objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) uploadImageWithSuccess:(void (^)())successBlock progress:(void (^)(float progress, long long totalBytes))progressBlock failure:(void (^)(NSError *error))errorBlock
{
    if (self.remoteURL.length) {
        // This means the bigger image was uploaded fine but the thumbnail could not be uploaded.
        // Upload only the thumbnail
        [self uploadThumbnailImageWithSuccess:successBlock progress:nil failure:errorBlock];
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
        self.filesize = [NSNumber numberWithUnsignedInteger:imageData.length];

        self.remoteStatus = MediaRemoteStatusPushing;
        __weak typeof(self) wself = self;
        NSString *filename = [NSString stringWithFormat:@"%@/%@_%@.jpg", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], self.filename];
        S3TransferOperation *operation = [self.remoteObject.transferManager uploadData:imageData withContentType:@"image/jpeg"
                                                                           forFileName:filename
                                                                          successBlock:^(NSString *url) {
                                                                              // Cache this in SDWebCache
                                                                              [[SDWebImageManager sharedManager].imageCache storeImage:image forKey:url toDisk:YES];
                                                                              
                                                                              wself.remoteURL = url;
                                                                              wself.filename = filename;
                                                                              
                                                                              // Bigger image has been successfully uploaded. Upload the thumbnail now
                                                                              [wself uploadThumbnailImageWithSuccess:successBlock progress:nil failure:errorBlock];
                                                                          }
                                                                         progressBlock:progressBlock
                                                                            errorBlock:errorBlock];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
            failureBlock:^(NSError *error) {
                errorBlock(error);
            }
     ];
}

- (void) uploadThumbnailImageWithSuccess:(void (^)())successBlock progress:(void (^)(float progress, long long totalBytes))progressBlock failure:(void (^)(NSError *error))errorBlock
{
    if (!self.thumbnail) {
        successBlock();
        return;
    }
    
    __weak typeof(self) wself = self;
    NSString *filename = [NSString stringWithFormat:@"%@/%@_%@_%@.jpg", [BNSharedUser currentUser].userId, [self.remoteObject getIdentifierForMediaFileName], [BNMisc genRandStringLength:10], NSStringFromCGSize(MEDIA_THUMBNAIL_SIZE)];
    
    S3TransferOperation *operation = [self.remoteObject.transferManager uploadData:UIImageJPEGRepresentation(self.thumbnail, 1)
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
                                                                     progressBlock:progressBlock
                                                                        errorBlock:errorBlock];
    objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) getImageWithContentMode:(UIViewContentMode)contentMode
                          bounds:(CGSize)size
            interpolationQuality:(CGInterpolationQuality)quality
             forMediaWithSuccess:(void (^)(UIImage *))success
                        progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize))progress
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
                            progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize))progress
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
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    if (includeThumbnail && [self.thumbnailURL length]) {
        [manager downloadWithURL:[NSURL URLWithString:self.thumbnailURL]
                         options:0
                        progress:progress
                       completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                           if (image) {
                               if (success) success(image);
                           }
                           else {
                               if (failure) failure(error);
                           }
                       }];
    } else if ([self.remoteURL length]) {
        [manager downloadWithURL:[NSURL URLWithString:self.remoteURL]
                         options:0
                        progress:progress
                       completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
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

- (void) saveMediaOnDevice
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:APP_DELEGATE.topMostController.view animated:YES];
    hud.labelText = @"Saving picture";
    hud.detailsLabelText = @"Saving picture to the camera roll";
    void (^completionHandler)(NSError *) = ^(NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud setMode:MBProgressHUDModeText];
            if (!error) {
                hud.labelText = @"Saved";
            } else {
                hud.labelText = @"Error";
                hud.detailsLabelText = @"There was an error in saving the picture";
            }
            [hud hide:YES afterDelay:1];
        });
    };
    
    [self getImageForMediaWithSuccess:^(UIImage *image) {
        [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error )
         {completionHandler(error);}];
    }
                             progress:nil
                              failure:^(NSError *error) {completionHandler(error);}
                     includeThumbnail:NO];
}

@end

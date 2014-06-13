//
//  UIImageView+BanyanMedia.m
//  Banyan
//
//  Created by Devang Mundhra on 11/10/13.
//
//

#import "UIImageView+BanyanMedia.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MBProgressHUD.h"

#define PROCESS_IMAGE(__image__) \
void (^block)(void) = ^\
{\
    __strong UIImageView *sself = wself;\
    if (!sself) return;\
    if (__image__) {\
        UIImage *pImage = nil;\
        if (postProcess)\
            pImage = postProcess(__image__);\
        else\
            pImage = image;\
        sself.image = pImage;\
        [sself setNeedsDisplay];\
    }\
};\
RUN_SYNC_ON_MAINTHREAD(block)

@implementation UIImageView (BanyanMedia)

- (void) showMedia:(Media *)media includeThumbnail:(BOOL)includeThumbnail withPostProcess:(UIImage *(^)(UIImage *image))postProcess
{
    // If we are just showing thumbnails, then no need to show a progress indicator.
    // Just show a placeholder image
    if (!media) {
        [self cancelCurrentImageLoad];
        [self setImageWithURL:nil];
        return;
    }
    
    assert([media.mediaType isEqualToString:@"image"] || [media.mediaType  isEqualToString:@"gif"]);
    
    if (includeThumbnail) {
        UIImage *image = media.thumbnail;
        UIImage *pImage = nil;
        if (image) {
            if (postProcess)
                pImage = postProcess(image);
            else
                pImage = image;
            self.image = pImage;
            [self setNeedsDisplay];
            return;
        }
    }
    
    UIImage *placeHolderImage = nil;
    __weak UIImageView *wself = self;
    if (includeThumbnail && [media.thumbnailURL length]) {
        [self setImageWithURL:[NSURL URLWithString:media.thumbnailURL]
             placeholderImage:placeHolderImage
                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                        PROCESS_IMAGE(image);
                    }];
    } else if ([media.remoteURL length]) {
        void (^fetchImageBlock)(void) = ^{
            __block MBProgressHUD *hud = nil;
            if (!includeThumbnail) {
                // Don't show progress view if thumbnail is included
                hud = [MBProgressHUD showHUDAddedTo:wself animated:YES];
                hud.mode = MBProgressHUDModeDeterminate;
            }
            [self setImageWithURL:[NSURL URLWithString:media.remoteURL]
                 placeholderImage:placeHolderImage
                          options:SDWebImageProgressiveDownload
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                             hud.progress = (float)receivedSize/expectedSize;
                         }
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                            RUN_SYNC_ON_MAINTHREAD(^{[hud hide:YES];});
                            PROCESS_IMAGE(image);
                        }];
        };
        RUN_SYNC_ON_MAINTHREAD(fetchImageBlock);
    } else if ([media.localURL length]) {
        ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
        [library assetForURL:[NSURL URLWithString:media.localURL] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef imageRef = [rep fullResolutionImage];
            UIImage *image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:(UIImageOrientation)[rep orientation]];
            PROCESS_IMAGE(image);
        }
                failureBlock:nil
         ];
    }
}

@end

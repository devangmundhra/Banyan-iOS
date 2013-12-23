//
//  UIImageView+BanyanMedia.m
//  Banyan
//
//  Created by Devang Mundhra on 11/10/13.
//
//

#import "UIImageView+BanyanMedia.h"
#import <AssetsLibrary/AssetsLibrary.h>

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
if ([NSThread isMainThread])\
{\
    block();\
}\
else\
{\
    dispatch_sync(dispatch_get_main_queue(), block);\
}

@implementation UIImageView (BanyanMedia)

- (void) showMedia:(Media *)media withPostProcess:(UIImage *(^)(UIImage *image))postProcess
{
    if (!media) {
        [self cancelCurrentImageLoad];
        [self setImageWithURL:nil];
        return;
    }
    
    assert([media.mediaType isEqualToString:@"image"] || [media.mediaType  isEqualToString:@"gif"]);
    
    __weak UIImageView *wself = self;
    if ([media.remoteURL length]) {
        [self setImageWithURL:[NSURL URLWithString:media.remoteURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            PROCESS_IMAGE(image);
        }];
    } else if ([media.localURL length]) {
        ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
        [library assetForURL:[NSURL URLWithString:media.localURL] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef imageRef = [rep fullResolutionImage];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            PROCESS_IMAGE(image);
        }
                failureBlock:nil
         ];
    }
}

- (void) showThumbnailOfMedia:(Media *)media withPostProcess:(UIImage *(^)(UIImage *image))postProcess
{
    if (!media) {
        [self cancelCurrentImageLoad];
        [self setImageWithURL:nil];
        return;
    }
    
    assert([media.mediaType isEqualToString:@"image"] || [media.mediaType  isEqualToString:@"gif"]);
    
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
    
    // If there is no thumbnail in the media-
    // Check first for the thumbnailURL, else the remoteURL, else the localURL
    __weak UIImageView *wself = self;
    if ([media.thumbnailURL length]) {
        [self setImageWithURL:[NSURL URLWithString:media.thumbnailURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            PROCESS_IMAGE(image);
        }];
    } else if ([media.remoteURL length]) {
        [self setImageWithURL:[NSURL URLWithString:media.remoteURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            PROCESS_IMAGE(image);
        }];
    } else if ([media.localURL length]) {
        ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
        [library assetForURL:[NSURL URLWithString:media.localURL] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef imageRef = [rep fullResolutionImage];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            PROCESS_IMAGE(image);
        }
                failureBlock:nil
         ];
    }
}

@end

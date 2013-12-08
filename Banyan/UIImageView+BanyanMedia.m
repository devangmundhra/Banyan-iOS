//
//  UIImageView+BanyanMedia.m
//  Banyan
//
//  Created by Devang Mundhra on 11/10/13.
//
//

#import "UIImageView+BanyanMedia.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation UIImageView (BanyanMedia)

- (void) showMedia:(Media *)media withPostProcess:(UIImage *(^)(UIImage *))postProcess
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
            if (!wself) return;
            __strong UIImageView *sself = wself;
            if (!sself) return;
            if (image) {
                UIImage *pImage = nil;
                if (postProcess)
                    pImage = postProcess(image);
                else
                    pImage = image;
                sself.image = pImage;
                [sself setNeedsDisplay];
            }
        }];
    } else if ([media.localURL length]) {
        ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
        [library assetForURL:[NSURL URLWithString:media.localURL] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef imageRef = [rep fullResolutionImage];
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            void (^block)(void) = ^
            {
                __strong UIImageView *sself = wself;
                if (!sself) return;
                
                UIImage *pImage = nil;
                if (postProcess)
                    pImage = postProcess(image);
                else
                    pImage = image;
                sself.image = pImage;
                [sself setNeedsDisplay];
            };
            if ([NSThread isMainThread])
            {
                block();
            }
            else
            {
                dispatch_sync(dispatch_get_main_queue(), block);
            }
        }
                failureBlock:nil
         ];
    }
}

@end

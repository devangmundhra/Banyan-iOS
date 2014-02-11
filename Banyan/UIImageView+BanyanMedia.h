//
//  UIImageView+BanyanMedia.h
//  Banyan
//
//  Created by Devang Mundhra on 11/10/13.
//
//

#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"
#import "Media.h"

@class Media;

@interface UIImageView (BanyanMedia)

- (void) showMedia:(Media *)media includeThumbnail:(BOOL)includeThumbnail withPostProcess:(UIImage *(^)(UIImage *image))postProcess;

@end

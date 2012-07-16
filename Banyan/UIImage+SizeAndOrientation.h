//
//  UIImage+SizeAndOrientation.h
//  Storied
//
//  Created by Devang Mundhra on 7/11/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (SizeAndOrientation)
#define radians( degrees ) ( degrees * M_PI / 180 )

- (UIImage *)fixOrientation;
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
+ (UIImage*)imageWithImage:(UIImage*)sourceImage scaledToSizeWithSameAspectRatio:(CGSize)targetSize;
@end

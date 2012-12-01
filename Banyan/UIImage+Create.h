//
//  UIImage+Create.h
//  Banyan
//
//  Created by Devang Mundhra on 11/29/12.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (Create)

+ (UIImage*) imageFilledWith:(UIColor*)color using:(UIImage*)startImage;
+ (UIImage *) imageFromText:(NSString *)text withSize:(CGFloat)size;
+ (UIImage *) imageWithColor:(UIColor *)color forRect:(CGRect)rect;

@end

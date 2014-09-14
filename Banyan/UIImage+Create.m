//
//  UIImage+Create.m
//  Banyan
//
//  Created by Devang Mundhra on 11/29/12.
//
//

#import "UIImage+Create.h"

@implementation UIImage (Create)

// Convert the image's fill color to the passed in color
+ (UIImage*) imageFilledWith:(UIColor*)color using:(UIImage*)startImage
{
    // Create the proper sized rect
    CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(startImage.CGImage), CGImageGetHeight(startImage.CGImage));
    
    // Create a new bitmap context
    CGContextRef context = CGBitmapContextCreate(NULL, imageRect.size.width, imageRect.size.height, 8, 0, CGImageGetColorSpace(startImage.CGImage), (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    // Use the passed in image as a clipping mask
    CGContextClipToMask(context, imageRect, startImage.CGImage);
    // Set the fill color
    CGContextSetFillColorWithColor(context, color.CGColor);
    // Fill with color
    CGContextFillRect(context, imageRect);
    
    // Generate a new image
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage* newImage = [UIImage imageWithCGImage:newCGImage scale:startImage.scale orientation:startImage.imageOrientation];
    
    // Cleanup
    CGContextRelease(context);
    CGImageRelease(newCGImage);
    
    return newImage;
}

// Get an image from text
+ (UIImage *) imageFromText:(NSString *)text withSize:(CGFloat)fontSize
{
    // set the font type and size
    UIFont *font = [UIFont systemFontOfSize:fontSize];    
    CGSize size  = [text sizeWithAttributes:@{NSFontAttributeName: font}];
    
    UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    
    // optional: add a shadow, to avoid clipping the shadow you should make the context size bigger
    //
    // CGContextRef ctx = UIGraphicsGetCurrentContext();
    // CGContextSetShadowWithColor(ctx, CGSizeMake(1.0, 1.0), 5.0, [[UIColor grayColor] CGColor]);
    
    // draw in context, you can use also drawInRect:withFont:
    [text drawAtPoint:CGPointMake(0.0, 0.0) withAttributes:@{NSFontAttributeName: font}];
    
    // transfer image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

// Get an image from text
+ (UIImage *) imageFromText:(NSString *)text withFont:(UIFont *)font withColor:(UIColor *)color
{
    // set the size
    CGSize size  = [text sizeWithAttributes:@{NSFontAttributeName: font}];
    
    UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    
    // optional: add a shadow, to avoid clipping the shadow you should make the context size bigger
    //
    // CGContextRef ctx = UIGraphicsGetCurrentContext();
    // CGContextSetShadowWithColor(ctx, CGSizeMake(1.0, 1.0), 5.0, [[UIColor grayColor] CGColor]);

    // draw in context, you can use also drawInRect:withFont:
    [text drawAtPoint:CGPointMake(0.0, 0.0) withAttributes:@{NSFontAttributeName: font,
                                                             NSForegroundColorAttributeName: color}];
    
    // transfer image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

// Get a rect filled with an image of a certain color
+ (UIImage *) imageWithColor:(UIColor *)color forRect:(CGRect)rect
{
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

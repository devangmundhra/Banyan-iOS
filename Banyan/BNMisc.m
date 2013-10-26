//
//  BNMisc.m
//  Banyan
//
//  Created by Devang Mundhra on 5/15/13.
//
//

#import "BNMisc.h"
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "BanyanAppDelegate.h"

@implementation BNMisc

#pragma mark Dates
+ (NSString *)longCurrentDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSString *)shortCurrentDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSDateFormatter *) dateFormatterNoTimeMediumDateRelative
{
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setDoesRelativeDateFormatting:YES];
    });
    
    return _dateFormatter;
}

+ (NSString *) genRandStringLength: (int) len
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

#pragma mark GIF Images
+ (NSString *) gifFromArray:(NSArray *)imagesArray
{
    NSUInteger kFrameCount = imagesArray.count;
    
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: @2.0f, // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              },
                                      (__bridge id)kCGImageDestinationLossyCompressionQuality: @1,
                                      };

    NSURL *documentsDirectoryURL = [BanyanAppDelegate applicationDocumentsDirectory];
    NSString *fileName = [NSString stringWithFormat:@"%@.gif", [BNMisc genRandStringLength:5]];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:fileName];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (NSUInteger i = 0; i < kFrameCount; i++) {
        @autoreleasepool {
            UIImage *image = [imagesArray objectAtIndex:i];
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
        CFRelease(destination);
        return nil;
    }
    CFRelease(destination);
    
    NSLog(@"url=%@", fileURL);
    return [fileURL absoluteString];
}

@end

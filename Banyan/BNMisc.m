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
    return [[self longDateFormatter] stringFromDate:[NSDate date]];
}

+ (NSString *)shortCurrentDate
{
    return [[self shortDateFormatter] stringFromDate:[NSDate date]];
}

+ (NSDateFormatter *) dateFormatterNoTimeMediumDateRelative
{
    static NSDateFormatter *_dateFormatterNoTimeMediumDateRelative = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatterNoTimeMediumDateRelative = [[NSDateFormatter alloc] init];
        [_dateFormatterNoTimeMediumDateRelative setTimeStyle:NSDateFormatterNoStyle];
        [_dateFormatterNoTimeMediumDateRelative setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatterNoTimeMediumDateRelative setDoesRelativeDateFormatting:YES];
    });
    
    return _dateFormatterNoTimeMediumDateRelative;
}

+ (NSDateFormatter *) dateTimeFormatter
{
    static NSDateFormatter *_dateTimeFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateTimeFormatter = [[NSDateFormatter alloc] init];
        [_dateTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_dateTimeFormatter setDateStyle:NSDateFormatterMediumStyle];
    });
    
    return _dateTimeFormatter;
}

+ (NSDateFormatter *) shortDateFormatter
{
    static NSDateFormatter *_dateTimeFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateTimeFormatter = [[NSDateFormatter alloc] init];
        [_dateTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_dateTimeFormatter setDateStyle:NSDateFormatterShortStyle];
    });
    
    return _dateTimeFormatter;
}

+ (NSDateFormatter *) longDateFormatter
{
    static NSDateFormatter *_dateTimeFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateTimeFormatter = [[NSDateFormatter alloc] init];
        [_dateTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_dateTimeFormatter setDateStyle:NSDateFormatterLongStyle];
    });
    
    return _dateTimeFormatter;
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

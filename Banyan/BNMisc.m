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
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

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
        BNLogError(@"failed to finalize image destination");
        CFRelease(destination);
        return nil;
    }
    CFRelease(destination);
    
    BNLogTrace(@"url=%@", fileURL);
    return [fileURL absoluteString];
}

+ (void) sendGoogleAnalyticsEventWithCategory:(NSString *)category
                                       action:(NSString *)action
                                        label:(NSString *)label
                                        value:(NSNumber *)value
{
    NSAssert(category, @"Need a category when recording event");
    NSAssert(action, @"Need an action when recording event");
    
    id<GAITracker>tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category
                                                          action:action
                                                           label:label
                                                           value:value] build]];
}

+ (void) sendGoogleAnalyticsSocialInteractionWithNetwork:(NSString *)socialNetwork
                                                  action:(NSString *)socialAction
                                                  target:(NSString *)target
{
    NSAssert(socialNetwork, @"Need a social network when recording social interactions");
    NSAssert(socialAction, @"Need a social action when recording socail interactions");
    
    id<GAITracker>tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createSocialWithNetwork:socialNetwork
                                                          action:socialAction
                                                          target:target] build]];
}

+ (void) sendGoogleAnalyticsException:(NSException *)exception inAction:(NSString *)action isFatal:(BOOL)fatal
{
    id<GAITracker>tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createExceptionWithDescription:[NSString stringWithFormat:@"%@ exception: %@", action, exception.reason]
                                                              withFatal:[NSNumber numberWithBool:fatal]] build]];
}

+ (void) sendGoogleAnalyticsError:(NSError *)error inAction:(NSString *)action isFatal:(BOOL)fatal
{
    id<GAITracker>tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createExceptionWithDescription:[NSString stringWithFormat:@"%@ error: %@", action, error.localizedDescription]
                                                              withFatal:[NSNumber numberWithBool:fatal]] build]];
}
@end

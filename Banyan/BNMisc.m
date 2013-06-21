//
//  BNMisc.m
//  Banyan
//
//  Created by Devang Mundhra on 5/15/13.
//
//

#import "BNMisc.h"

@implementation BNMisc

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
@end

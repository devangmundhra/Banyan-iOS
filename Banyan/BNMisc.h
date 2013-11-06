//
//  BNMisc.h
//  Banyan
//
//  Created by Devang Mundhra on 5/15/13.
//
//

#import <Foundation/Foundation.h>

@interface BNMisc : NSObject

+ (NSString *)longCurrentDate;
+ (NSString *)shortCurrentDate;
+ (NSString *) genRandStringLength: (int) len;
+ (NSDateFormatter *) dateFormatterNoTimeMediumDateRelative;
+ (NSDateFormatter *) dateTimeFormatter;
+ (NSString *) gifFromArray:(NSArray *)imagesArray;

@end


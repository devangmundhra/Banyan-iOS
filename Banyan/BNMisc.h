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
+ (NSDateFormatter *) longDateFormatter;
+ (NSDateFormatter *) shortDateFormatter;
+ (NSString *) gifFromArray:(NSArray *)imagesArray;
+ (void) showLocationServicesAlertIfRequired;

+ (void) sendGoogleAnalyticsEventWithCategory:(NSString *)category
                                       action:(NSString *)action
                                        label:(NSString *)label
                                        value:(NSNumber *)value;

+ (void) sendGoogleAnalyticsSocialInteractionWithNetwork:(NSString *)socialNetwork
                                                  action:(NSString *)socialAction
                                                  target:(NSString *)target;

+ (void) sendGoogleAnalyticsException:(NSException *)exception inAction:(NSString *)action isFatal:(BOOL)fatal;
+ (void) sendGoogleAnalyticsError:(NSError *)error inAction:(NSString *)action isFatal:(BOOL)fatal;

@end


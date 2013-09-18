//
//  BNAWSSNSClient.h
//  Banyan
//
//  Created by Devang Mundhra on 9/7/13.
//
//

#import <Foundation/Foundation.h>
#import <AWSRuntime/AWSRuntime.h>
#import <AWSSNS/AWSSNS.h>

@interface BNAWSSNSClient : NSObject

+ (void) registerDeviceToken:(NSString *)deviceToken;
+ (NSMutableDictionary *)endpointsDict;
+ (void) enableNotificationsFromChannel:(NSString *)channel forEndpointArn:(NSString *)arn;
+ (void) disableNotificationsFromChannel:(NSString *)channel forEndpointArn:(NSString *)arn;

@end

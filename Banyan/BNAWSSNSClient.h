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

// SNS endpoint app strings
extern NSString *const BNAWSSNSInvitedToContributeString;
extern NSString *const BNAWSSNSInvitedToViewString;
extern NSString *const BNAWSSNSPieceAddedString;
extern NSString *const BNAWSSNSPieceActionString;
extern NSString *const BNAWSSNSUserFollowingString;

@interface BNAWSSNSClient : NSObject

+ (void) registerDeviceToken:(NSString *)deviceToken withCompletionBlock:(void(^)(void))block;
+ (NSMutableDictionary *)endpointsDict;
+ (void) enableNotificationsFromChannel:(NSString *)channel
                         forEndpointArn:(NSString *)arn
                  inBackgroundWithBlock:(void (^)(bool succeeded, NSError *error))block;
+ (void) disableNotificationsFromChannel:(NSString *)channel
                          forEndpointArn:(NSString *)arn
                   inBackgroundWithBlock:(void (^)(bool succeeded, NSError *error))block;

@end

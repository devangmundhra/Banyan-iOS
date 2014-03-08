//
//  BNAWSSNSClient.m
//  Banyan
//
//  Created by Devang Mundhra on 9/7/13.
//
//

#import "BNAWSSNSClient.h"
#import "BanyanAppDelegate.h"
#import "AFBanyanAPIClient.h"
#import "User.h"

@implementation BNAWSSNSClient

+ (AmazonSNSClient *)sharedClient
{
    static AmazonSNSClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AmazonSNSClient alloc] initWithAccessKey:AWS_ACCESS_KEY withSecretKey:AWS_SECRET_KEY];
    });
    
    return _sharedClient;
}

+ (NSMutableDictionary *) endpointsDict
{
    static NSMutableDictionary *_endpointArnDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _endpointArnDict = [[NSMutableDictionary alloc] init];
    });
    return _endpointArnDict;
}

+ (void) registerDeviceToken:(NSString *)deviceToken
{
    // If this is running in simulator, don't do anything
    if (!deviceToken) {
        return;
    }
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(queue, ^{
        BNSharedUser *currentUser = [BNSharedUser currentUser];
        if (!currentUser) {
            [BNMisc sendGoogleAnalyticsEventWithCategory:@"Error" action:@"No current user when registering device" label:nil value:nil];
            return;
        }
        
        SNSCreatePlatformEndpointRequest *req = [[SNSCreatePlatformEndpointRequest alloc] init];
        req.token = deviceToken;

        SNSCreatePlatformEndpointResponse *resp = nil;
        @try {
            req.platformApplicationArn = AWS_APPARN_INVTOCONTRIBUTE;
            resp = [[self sharedClient] createPlatformEndpoint:req];
            [[self endpointsDict] setObject:resp.endpointArn forKey:@"InvitedToContribute"];
            req.platformApplicationArn = AWS_APPARN_INVTOVIEW;
            resp = [[self sharedClient] createPlatformEndpoint:req];
            [[self endpointsDict] setObject:resp.endpointArn forKey:@"InvitedToView"];
            req.platformApplicationArn = AWS_APPARN_PIECEACTION;
            resp = [[self sharedClient] createPlatformEndpoint:req];
            [[self endpointsDict] setObject:resp.endpointArn forKey:@"PieceAction"];
            req.platformApplicationArn = AWS_APPARN_PIECEADDED;
            resp = [[self sharedClient] createPlatformEndpoint:req];
            [[self endpointsDict] setObject:resp.endpointArn forKey:@"PieceAdded"];
            req.platformApplicationArn = AWS_APPARN_USERFOLLOWING;
            resp = [[self sharedClient] createPlatformEndpoint:req];
            [[self endpointsDict] setObject:resp.endpointArn forKey:@"UserFollowing"];
            
            [[AFBanyanAPIClient sharedClient] putPath:[NSString stringWithFormat:@"%@%@/", currentUser.resourceUri, @"installations"]
                                           parameters:@{@"device_token":deviceToken, @"type":[UIDevice currentDevice].systemName, @"push_endpoints": @{@"apns": [self endpointsDict]}}
                                              success:nil
                                              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                  BNLogError(@"An error occurred: %@", error.localizedDescription);
                                              }];
        }
        @catch (NSException *exception) {
            [BNMisc sendGoogleAnalyticsException:exception inAction:@"Create SNS Endpoint" isFatal:NO];
            BNLogError(@"Exception is: %@", exception.description);
        }
    });
}

+ (void) enableNotificationsFromChannel:(NSString *)channel forEndpointArn:(NSString *)arn inBackgroundWithBlock:(void (^)(bool succeeded, NSError *error))block
{
    if (!arn)
        return;

    [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"enableNotification" label:channel value:nil];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(queue, ^{
        SNSSetEndpointAttributesRequest *req = [[SNSSetEndpointAttributesRequest alloc] init];
        req.endpointArn = arn;
        [req setAttributesValue:@"true" forKey:@"Enabled"];
        @try {
            [[self sharedClient] setEndpointAttributes:req];
            if (block) block(YES, nil);
        }
        @catch (NSException *exception) {
            BNLogError(@"Exception is: %@", exception.description);
            [BNMisc sendGoogleAnalyticsException:exception inAction:@"Enable SNS Notification" isFatal:NO];
            if (block) block(NO, nil);
        }
    });
}

+ (void) disableNotificationsFromChannel:(NSString *)channel forEndpointArn:(NSString *)arn inBackgroundWithBlock:(void (^)(bool succeeded, NSError *error))block;
{
    if (!arn)
        return;
    
    [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"disableNotification" label:channel value:nil];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(queue, ^{
        SNSSetEndpointAttributesRequest *req = [[SNSSetEndpointAttributesRequest alloc] init];
        req.endpointArn = arn;
        [req setAttributesValue:@"false" forKey:@"Enabled"];
        @try {
            [[self sharedClient] setEndpointAttributes:req];
            if (block) block(YES, nil);
        }
        @catch (NSException *exception) {
            [BNMisc sendGoogleAnalyticsException:exception inAction:@"Disable SNS Notification" isFatal:NO];
            BNLogError(@"Exception is: %@", exception.description);
            if (block) block(NO, nil);
        }
    });
}

@end

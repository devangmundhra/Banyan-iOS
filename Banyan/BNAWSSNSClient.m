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

static NSMutableDictionary *_endpointArnDict = nil;

@implementation BNAWSSNSClient

+ (AmazonSNSClient *)sharedClient
{
    static AmazonSNSClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AmazonSNSClient alloc] initWithAccessKey:AWS_ACCESS_KEY withSecretKey:AWS_SECRET_KEY];
        _endpointArnDict = [[NSMutableDictionary alloc] init];
    });
    
    return _sharedClient;
}

+ (NSDictionary *) getEndpointsDict
{
    return [_endpointArnDict copy];
}

+ (void) registerDeviceToken:(NSString *)deviceToken
{
    SNSCreatePlatformEndpointRequest *req = [[SNSCreatePlatformEndpointRequest alloc] init];
    req.token = deviceToken;
    SNSCreatePlatformEndpointResponse *resp = nil;
    @try {
        req.platformApplicationArn = AWS_APPARN_INVTOCONTRIBUTE;
        resp = [[self sharedClient] createPlatformEndpoint:req];
        [_endpointArnDict setObject:resp.endpointArn forKey:@"InvitedToContribute"];
        req.platformApplicationArn = AWS_APPARN_INVTOVIEW;
        resp = [[self sharedClient] createPlatformEndpoint:req];
        [_endpointArnDict setObject:resp.endpointArn forKey:@"InvitedToView"];
        req.platformApplicationArn = AWS_APPARN_PIECEACTION;
        resp = [[self sharedClient] createPlatformEndpoint:req];
        [_endpointArnDict setObject:resp.endpointArn forKey:@"PieceAction"];
        req.platformApplicationArn = AWS_APPARN_PIECEADDED;
        resp = [[self sharedClient] createPlatformEndpoint:req];
        [_endpointArnDict setObject:resp.endpointArn forKey:@"PieceAdded"];
        req.platformApplicationArn = AWS_APPARN_USERFOLLOWING;
        resp = [[self sharedClient] createPlatformEndpoint:req];
        [_endpointArnDict setObject:resp.endpointArn forKey:@"UserFollowing"];
        
        BNSharedUser *currentUser = [BNSharedUser currentUser];
        
        if (currentUser) {
            [[AFBanyanAPIClient sharedClient] putPath:currentUser.resourceUri
                                           parameters:@{@"push_endpoints": @{@"apns": [BNAWSSNSClient getEndpointsDict]}}
                                              success:nil
                                              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                  NSLog(@"An error occurred: %@", error.localizedDescription);
                                              }];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception is: %@", exception.description);
    }
}

+ (void) enableNotificationsFromChannel:(NSString *)channel forEndpointArn:(NSString *)arn
{
    if (!arn)
        return;

    SNSSetEndpointAttributesRequest *req = [[SNSSetEndpointAttributesRequest alloc] init];
    req.endpointArn = arn;
    [req setAttributesValue:@"true" forKey:@"Enabled"];
    @try {
        [[self sharedClient] setEndpointAttributes:req];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception is: %@", exception.description);
    }
}

+ (void) disableNotificationsFromChannel:(NSString *)channel forEndpointArn:(NSString *)arn
{
    if (!arn)
        return;

    SNSSetEndpointAttributesRequest *req = [[SNSSetEndpointAttributesRequest alloc] init];
    req.endpointArn = arn;
    [req setAttributesValue:@"false" forKey:@"Enabled"];
    @try {
        [[self sharedClient] setEndpointAttributes:req];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception is: %@", exception.description);
    }
}

@end
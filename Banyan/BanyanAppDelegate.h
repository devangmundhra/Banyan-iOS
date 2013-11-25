//
//  BanyanAppDelegate.h
//  Banyan
//
//  Created by Devang Mundhra on 7/15/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AWS_ACCESS_KEY @"AKIAJ3LJBD4SE3HS4NIQ"
#define AWS_SECRET_KEY @"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"

#define AWS_APPARN_INVTOCONTRIBUTE @"arn:aws:sns:us-east-1:925059984507:app/APNS_SANDBOX/Banyan_SBX_InvToContribute"
#define AWS_APPARN_INVTOVIEW @"arn:aws:sns:us-east-1:925059984507:app/APNS_SANDBOX/Banyan_SBX_InvToView"
#define AWS_APPARN_PIECEACTION @"arn:aws:sns:us-east-1:925059984507:app/APNS_SANDBOX/Banyan_SBX_PieceAction"
#define AWS_APPARN_PIECEADDED @"arn:aws:sns:us-east-1:925059984507:app/APNS_SANDBOX/Banyan_SBX_PieceAddedToFollowedStory"
#define AWS_APPARN_USERFOLLOWING @"arn:aws:sns:us-east-1:925059984507:app/APNS_SANDBOX/Banyan_SBX_UserFollowing"

#define FACEBOOK_APP_ID @"244613942300893"
#define TESTFLIGHT_BANYAN_APP_TOKEN @"ebf0542f-c311-4378-b6d0-1f14c6fdf4a6"

#define GOOGLE_API_KEY @"AIzaSyBwOBP068EO-Ubi0Qzu8uwFnZZHaIVwNyg"

#define APP_DELEGATE ((BanyanAppDelegate *)([UIApplication sharedApplication].delegate))
@interface BanyanAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void) fireRemoteObjectTimer;
- (void) invalidateRemoteObjectTimer;

//- (BOOL) openSessionWithAllowLoginUI:(BOOL)allowLoginUI;;
- (void) login;
- (void) logout;
+ (BOOL)loggedIn;
- (UIViewController*) topMostController;
+ (NSURL *)applicationDocumentsDirectory;
+ (BOOL) isFirstTimeUser;
@end
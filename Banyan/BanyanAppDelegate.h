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

#ifdef DEBUG
#define AWS_APPARN_INVTOCONTRIBUTE @"arn:aws:sns:us-east-1:925059984507:app/APNS_SANDBOX/Banyan_SBX_InvToContribute"
#define AWS_APPARN_INVTOVIEW @"arn:aws:sns:us-east-1:925059984507:app/APNS_SANDBOX/Banyan_SBX_InvToView"
#define AWS_APPARN_PIECEACTION @"arn:aws:sns:us-east-1:925059984507:app/APNS_SANDBOX/Banyan_SBX_PieceAction"
#define AWS_APPARN_PIECEADDED @"arn:aws:sns:us-east-1:925059984507:app/APNS_SANDBOX/Banyan_SBX_PieceAddedToFollowedStory"
#define AWS_APPARN_USERFOLLOWING @"arn:aws:sns:us-east-1:925059984507:app/APNS_SANDBOX/Banyan_SBX_UserFollowing"
#else
#define AWS_APPARN_INVTOCONTRIBUTE @"arn:aws:sns:us-east-1:925059984507:app/APNS/Banyan_PROD_InvToContribute"
#define AWS_APPARN_INVTOVIEW @"arn:aws:sns:us-east-1:925059984507:app/APNS/Banyan_PROD_InvToView"
#define AWS_APPARN_PIECEACTION @"arn:aws:sns:us-east-1:925059984507:app/APNS/Banyan_PROD_PieceAction"
#define AWS_APPARN_PIECEADDED @"arn:aws:sns:us-east-1:925059984507:app/APNS/Banyan_PROD_PieceAddedToFollowedStory"
#define AWS_APPARN_USERFOLLOWING @"arn:aws:sns:us-east-1:925059984507:app/APNS/Banyan_PROD_UserFollowing"
#endif

#define FACEBOOK_APP_ID @"244613942300893"

#define GOOGLE_API_KEY @"AIzaSyBwOBP068EO-Ubi0Qzu8uwFnZZHaIVwNyg"
#define GOOGLE_ANALYTICS_ID @"UA-35913422-2"

#define CRASHLYTICS_API_KEY @"2af776d8f9dd545aa2bcb6afef1d780cfc5a1ee0"
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
@end
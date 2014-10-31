//
//  BanyanAppDelegate.h
//  Banyan
//
//  Created by Devang Mundhra on 7/15/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <UIKit/UIKit.h>

#define BANYAN_APP_ID @"824087526"

#define APP_DELEGATE ((BanyanAppDelegate *)([UIApplication sharedApplication].delegate))

// Add the following credentials for debugging

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

#ifdef DEBUG
#define AWS_ACCESS_KEY @""
#define AWS_SECRET_KEY @""
#else
#define AWS_ACCESS_KEY @""
#define AWS_SECRET_KEY @""
#endif

#define FACEBOOK_APP_ID @""

#define GOOGLE_IOS_API_KEY @""
#define GOOGLE_BROWSER_API_KEY @""
#define GOOGLE_ANALYTICS_ID @""

#define CRASHLYTICS_API_KEY @""

#define AVIARY_KEY @""
#define AVIARY_SECRET @""

@interface BanyanAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//- (BOOL) openSessionWithAllowLoginUI:(BOOL)allowLoginUI;;
- (void) login;
- (void) logout;
+ (BOOL)loggedIn;
- (UIViewController*) topMostController;
+ (NSURL *)applicationDocumentsDirectory;
- (void) cleanupBeforeExit;
@end
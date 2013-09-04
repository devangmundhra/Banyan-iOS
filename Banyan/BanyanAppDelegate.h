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

#define FACEBOOK_APP_ID @"244613942300893"
#define TESTFLIGHT_BANYAN_APP_TOKEN @"ebf0542f-c311-4378-b6d0-1f14c6fdf4a6"

#define GOOGLE_API_KEY @"AIzaSyBwOBP068EO-Ubi0Qzu8uwFnZZHaIVwNyg"

@class MasterTabBarController;
@interface BanyanAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) MasterTabBarController *tabBarController;

- (void) fireRemoteObjectTimer;
- (void) invalidateRemoteObjectTimer;

//- (BOOL) openSessionWithAllowLoginUI:(BOOL)allowLoginUI;;
- (void) login;
- (void) logout;
+ (BOOL)loggedIn;
+ (UIViewController*) topMostController;
+ (NSURL *)applicationDocumentsDirectory;

@end
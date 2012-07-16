//
//  UserManagementModule.h
//  Storied
//
//  Created by Devang Mundhra on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginTabbarViewController.h"
#import "UserLoginViewController.h"
#import <Parse/Parse.h>
#import "User_Defines.h"

#define USER_MANAGEMENT_MODULE_USER_LOGIN_NOTIFICATION @"UserManagementModule_UserLoggedIn"
#define USER_MANAGEMENT_MODULE_USER_LOGOUT_NOTIFICATION @"UserManagementModule_UserLoggedOut"

@interface UserManagementModule : NSObject <PF_FBSessionDelegate, PF_FBDialogDelegate, PF_FBRequestDelegate, 
                                            UserLoginViewControllerDelegate> {
    UIViewController *owningViewController;
}

@property (nonatomic, strong) UIViewController *owningViewController;

- (BOOL)isUserSignedIntoApp;
- (void)addLoginTabbar;
- (void)removeLoginTabbar;
- (void)login;
- (void)logout;

@end

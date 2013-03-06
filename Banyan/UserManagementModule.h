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
#import "User.h"

@interface UserManagementModule : NSObject <UserLoginViewControllerDelegate>

- (BOOL)isUserSignedIntoApp;
- (void)addLoginTabbar;
- (void)removeLoginTabbar;
- (void)login;
- (void)logout;

@end

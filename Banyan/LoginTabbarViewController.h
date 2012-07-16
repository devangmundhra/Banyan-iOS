//
//  LoginTabbarViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserManagementModule.h"

@class UserManagementModule;

@interface LoginTabbarViewController : UIViewController

@property (nonatomic, weak) UserManagementModule *module;

@end

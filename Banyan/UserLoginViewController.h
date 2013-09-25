//
//  UserLoginViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserLoginViewController;

@protocol UserLoginViewControllerDelegate <NSObject>

- (void) loginViewControllerDidLoginWithFacebookUser:(id<FBGraphUser>)user;


@end

@interface UserLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet id<UserLoginViewControllerDelegate> delegate;

@end
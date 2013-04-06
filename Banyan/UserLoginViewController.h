//
//  UserLoginViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Parse/Parse.h"

@class UserLoginViewController;

@protocol UserLoginViewControllerDelegate <NSObject>

- (void)logInViewController:(UserLoginViewController *)logInController didLogInUser:(PFUser *)user;

@end

@interface UserLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet id<UserLoginViewControllerDelegate> delegate;
@property (strong, nonatomic) NSArray *facebookPermissions;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
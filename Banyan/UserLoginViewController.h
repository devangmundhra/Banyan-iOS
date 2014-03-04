//
//  UserLoginViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 3/29/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserLoginViewController;

@protocol UserLoginViewControllerDelegate <NSObject>

- (void) loginViewControllerDidLoginWithFacebookUser:(id<FBGraphUser>)user
                                 withCompletionBlock:(void (^)(bool succeeded, NSError *error))block;

@end

@interface UserLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet id<UserLoginViewControllerDelegate> delegate;

@end
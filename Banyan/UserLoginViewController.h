//
//  UserLoginViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 3/29/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const fbLoginNoUserEmailAlert;

@class UserLoginViewController;

@protocol UserLoginViewControllerDelegate <NSObject>

- (void) loginViewController:(UserLoginViewController *)loginVC didLoginWithFacebookUser:(id<FBGraphUser>)user
                                    withCompletionBlock:(void (^)(bool succeeded, NSError *error))block;

@end

@interface UserLoginViewController : UIViewController <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet id<UserLoginViewControllerDelegate> delegate;

@end
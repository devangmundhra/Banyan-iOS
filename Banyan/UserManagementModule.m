//
//  UserManagementModule.m
//  Storied
//
//  Created by Devang Mundhra on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserManagementModule.h"
#import "BanyanAppDelegate.h"
#import "User+Edit.h"

@interface UserManagementModule() {
    LoginTabbarViewController *loginTabbarViewController;
}

@property (nonatomic, strong) LoginTabbarViewController *loginTabbarViewController;
@property (nonatomic, strong) UIViewController *owningViewController;

@end

@implementation UserManagementModule

@synthesize loginTabbarViewController;
@synthesize owningViewController;

- (id)init
{
    self = [super init];
    if (self) {
        loginTabbarViewController = [[LoginTabbarViewController alloc] init];
        loginTabbarViewController.module = self;
        owningViewController = nil;
    }
    return self;
}

- (BOOL) isUserSignedIntoApp
{
    if ([User loggedIn]) {
        [self removeLoginTabbar];
        return  YES;
    } else {
        [self addLoginTabbar];
        return NO;
    }
}


- (void)addLoginTabbar
{
    if (!loginTabbarViewController) {
        loginTabbarViewController = [[LoginTabbarViewController alloc] init];
        loginTabbarViewController.module = self;
    }
    
    // Allocate a view controller and show it here
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect viewRect = loginTabbarViewController.view.frame;
    loginTabbarViewController.view.frame = CGRectMake(0, screenRect.size.height - viewRect.size.height, 
                                                      viewRect.size.width, viewRect.size.height);
    if ([window.subviews indexOfObject:loginTabbarViewController.view] == NSNotFound 
        || loginTabbarViewController.view.alpha < 1) {
        loginTabbarViewController.view.alpha = 1;
        [window addSubview:loginTabbarViewController.view];
    }
    [window bringSubviewToFront:loginTabbarViewController.view];
}

- (void)removeLoginTabbar
{
    // Remove the view from the window
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    if ([window.subviews indexOfObject:loginTabbarViewController.view] != NSNotFound) {
        [loginTabbarViewController.view removeFromSuperview];
    }
    
    // Deallocate the view controller
    loginTabbarViewController = nil;
}

#pragma mark: target actions
- (void)login
{
    // animate the tabbar up to the screen
    UserLoginViewController *userLoginViewController = [[UserLoginViewController alloc] init];
    userLoginViewController.delegate = self;
    userLoginViewController.facebookPermissions = [NSArray arrayWithObjects: @"email", @"user_about_me", nil];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.4];
    [UIView setAnimationDelay:0.11];
    CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];
    CGRect viewRect = loginTabbarViewController.view.frame;
    loginTabbarViewController.view.frame = CGRectMake(0, 0 - viewRect.size.height + statusRect.size.height, 
                                                      viewRect.size.width, viewRect.size.height);
    loginTabbarViewController.view.alpha = 0;
    [UIView commitAnimations];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
    self.owningViewController = [BanyanAppDelegate topMostController];
    [self.owningViewController presentViewController:userLoginViewController animated:YES completion:nil];
}

- (void)logout
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:BNUserDefaultsUserInfo];
    [defaults removeObjectForKey:BNUserDefaultsFacebookFriends];
    [defaults synchronize];
    [PFPush unsubscribeFromChannelInBackground:[[PFUser currentUser] objectId]];
    [PFUser logOut];
    [[NSNotificationCenter defaultCenter] postNotificationName:BNUserLogOutNotification
                                                        object:self];
    [self addLoginTabbar];
    return;
}

# pragma mark UserLoginViewControllerDelegate
- (void)logInViewController:(UserLoginViewController *)logInController didLogInUser:(PFUser *)user
{
    NSLog(@"Getting user info");
    [PF_FBRequestConnection startForMeWithCompletionHandler:^(PF_FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            [(BanyanAppDelegate *)[[UIApplication sharedApplication] delegate] facebookRequest:connection didLoad:result];
        } else {
            [(BanyanAppDelegate *)[[UIApplication sharedApplication] delegate] facebookRequest:connection didFailWithError:error];
        }
    }];
    [PFPush subscribeToChannelInBackground:[[PFUser currentUser] objectId]];
    
    [self.owningViewController.presentedViewController dismissViewControllerAnimated:YES completion:^{
        [self removeLoginTabbar];
        if ([self.owningViewController respondsToSelector:@selector(refreshView)]) {
            [self.owningViewController performSelector:@selector(refreshView)];
        }
        self.owningViewController = nil;
    }];
}

- (void)logInViewControllerDidCancelLogIn:(UserLoginViewController *)logInController
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.4];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect viewRect = loginTabbarViewController.view.frame;
    loginTabbarViewController.view.frame = CGRectMake(0, screenRect.size.height - viewRect.size.height, 
                                                      viewRect.size.width, viewRect.size.height);
    loginTabbarViewController.view.alpha = 1;
    [UIView commitAnimations];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];

    [self.owningViewController.presentedViewController dismissViewControllerAnimated:YES completion:^{
        self.owningViewController = nil;
    }];
}

@end

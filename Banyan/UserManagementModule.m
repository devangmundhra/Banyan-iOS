//
//  UserManagementModule.m
//  Storied
//
//  Created by Devang Mundhra on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserManagementModule.h"

@interface UserManagementModule() {
    LoginTabbarViewController *loginTabbarViewController;
}

@property (nonatomic, strong) LoginTabbarViewController *loginTabbarViewController;

@end

@implementation UserManagementModule

@synthesize loginTabbarViewController;
@synthesize owningViewController;

- (id)init
{
    self = [super init];
    if (self) {
        [PFFacebookUtils initializeWithApplicationId:@"244613942300893"];
        
        loginTabbarViewController = [[LoginTabbarViewController alloc] init];
        loginTabbarViewController.module = self;
        owningViewController = nil;
    }
    return self;
}

- (BOOL) isUserSignedIntoApp
{
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser)
    {
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
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
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
//        [loginTabbarViewController removeFromParentViewController];
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
    userLoginViewController.facebookPermissions = [NSArray arrayWithObjects: @"email", @"user_about_me", @"publish_stream", nil];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.4];
    [UIView setAnimationDelay:0.09];
    CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];
    CGRect viewRect = loginTabbarViewController.view.frame;
    loginTabbarViewController.view.frame = CGRectMake(0, 0 - viewRect.size.height + statusRect.size.height, 
                                                      viewRect.size.width, viewRect.size.height);
    loginTabbarViewController.view.alpha = 0;
    [UIView commitAnimations];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
    [self.owningViewController presentViewController:userLoginViewController animated:YES completion:nil];
}

- (void)logout
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"User Info"];
    [defaults synchronize];
    [PFPush unsubscribeFromChannelInBackground:[[PFUser currentUser] objectId]];
    [PFUser logOut];
    [User updateCurrentUser];
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_MANAGEMENT_MODULE_USER_LOGOUT_NOTIFICATION
                                                        object:self];
    return;
}

# pragma mark UserLoginViewControllerDelegate
- (void)logInViewController:(UserLoginViewController *)logInController didLogInUser:(PFUser *)user
{
    [self.owningViewController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"Getting user info");
    [self getUserInfo:self];
    [PFPush subscribeToChannelInBackground:[[PFUser currentUser] objectId]];
    [User updateCurrentUser];
    // View refreshed after login notification sent    
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

    [self.owningViewController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - FBSessionDelegate, PF_FBSessionDelegate

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[PFFacebookUtils facebook] accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[[PFFacebookUtils facebook] expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

- (void) fbDidLogout {
    // Remove saved authorization information if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
        [defaults synchronize];
    }
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
    NSLog(@"token extended");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:accessToken forKey:@"FBAccessTokenKey"];
    [defaults setObject:expiresAt forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

/**
 * Called when the user dismissed the dialog without logging in.
 */
- (void)fbDidNotLogin:(BOOL)cancelled
{

}

/**
 * Called when the current session has expired. This might happen when:
 *  - the access token expired
 *  - the app has been disabled
 *  - the user revoked the app's permissions
 *  - the user changed his or her password
 */
- (void)fbSessionInvalidated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[PFFacebookUtils facebook] accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[[PFFacebookUtils facebook] expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

# pragma mark PF_FBRequestDelegate

- (void)request:(PF_FBRequest *)request didLoad:(id)result
{
    // User info
    if ([result isKindOfClass:[NSDictionary class]] && [PFUser currentUser])
    {
        NSDictionary *resultsDict = result;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:resultsDict forKey:@"User Info"];
        [defaults synchronize];
        
        PFUser *currentUser = [PFUser currentUser];
        [currentUser setEmail:[resultsDict objectForKey:@"email"]];
        [currentUser setObject:[resultsDict objectForKey:@"name"] forKey:USER_NAME];
        if (currentUser.isNew) {
            [currentUser setUsername:[resultsDict objectForKey:@"email"]];
            [currentUser setObject:[resultsDict objectForKey:@"id"] forKey:USER_FACEBOOK_ID];
        }
        [currentUser saveEventually];
        [[NSNotificationCenter defaultCenter] postNotificationName:USER_MANAGEMENT_MODULE_USER_LOGIN_NOTIFICATION 
                                                            object:self];
    }
}

- (void)getUserInfo:(id)sender
{
    [[PFFacebookUtils facebook] requestWithGraphPath:@"me" andDelegate:self];
}

@end

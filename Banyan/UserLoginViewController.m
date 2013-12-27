//
//  UserLoginViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserLoginViewController.h"

@interface UserLoginViewController () <FBLoginViewDelegate>
@property (weak, nonatomic) IBOutlet FBLoginView *fbLoginView;

@end

@implementation UserLoginViewController
@synthesize fbLoginView = _fbLoginView;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Get started!";
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];

	// Do any additional setup after loading the view, typically from a nib.
    self.fbLoginView.readPermissions = [NSArray arrayWithObjects: @"email", @"user_about_me", @"user_photos", nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark target actions

//- (IBAction)facebookLogin:(UIButton *)sender 
//{
//    [FBSession openActiveSessionWithReadPermissions:self.facebookPermissions
//                                       allowLoginUI:YES
//                                  completionHandler:^(FBSession *session,
//                                                      FBSessionState status,
//                                                      NSError *error) {
//                                      [self.activityIndicator stopAnimating]; // Hide loading indicator
//                                      if (error) {
//                                          NSLog(@"Uh oh. An error occurred: %@", error);
//                                          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
//                                          [alert show];
//                                      } else {
//                                          // Respond to session state changes
//                                          if ([session isOpen]) {
//                                              // Call the banyan api to get the real user data
//                                              [self.delegate logInViewController:self didLogInUser:nil];
//                                          } else {
//                                              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"Unable to open an active session on facebook" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
//                                              [alert show];
//                                          }
//                                      }
//                                  }];
//    
//    [self.activityIndicator startAnimating]; // Show loading indicator until login is finished
//    [self dismissViewControllerAnimated:YES completion:nil];
//    return;
//}

- (IBAction)cancel:(id)sender 
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark FBLoginViewDelegate methods
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user
{
    [self.delegate loginViewControllerDidLoginWithFacebookUser:user];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loginView:(FBLoginView *)loginView
      handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;
    if (error.fberrorShouldNotifyUser) {
        // If the SDK has a message for the user, surface it. This conveniently
        // handles cases like password change or iOS6 app slider state.
        alertTitle = @"Facebook Error";
        alertMessage = error.fberrorUserMessage;
    } else if (error.fberrorCategory == FBErrorCategoryAuthenticationReopenSession) {
        // It is important to handle session closures since they can happen
        // outside of the app. You can inspect the error for more context
        // but this sample generically notifies the user.
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
    } else if (error.fberrorCategory == FBErrorCategoryUserCancelled) {
        // The user has cancelled a login. You can inspect the error
        // for more context. For this sample, we will simply ignore it.
        NSLog(@"user cancelled login");
    } else {
        // For simplicity, this sample treats other errors blindly.
        alertTitle  = @"Unknown Error";
        alertMessage = @"Error. Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end

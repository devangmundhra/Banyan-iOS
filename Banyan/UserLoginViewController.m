//
//  UserLoginViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserLoginViewController.h"
#import "AppDelegate.h"

@interface UserLoginViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *backNavigationItem;
@property (weak, nonatomic) IBOutlet UITextField *emailAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation UserLoginViewController
@synthesize cancelButton = _cancelButton;
@synthesize facebookLoginButton = _facebookLoginButton;
@synthesize navigationBar = _navigationBar;
@synthesize backNavigationItem = _backNavigationItem;
@synthesize emailAddressTextField = _emailAddressTextField;
@synthesize passwordTextField = _passwordTextField;
@synthesize delegate = _delegate;
@synthesize facebookPermissions = _facebookPermissions;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.emailAddressTextField.hidden = self.passwordTextField.hidden = YES;
}

- (void)viewDidUnload
{
    [self setFacebookLoginButton:nil];
    [self setNavigationBar:nil];
    [self setBackNavigationItem:nil];
    [self setCancelButton:nil];
    [self setEmailAddressTextField:nil];
    [self setPasswordTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark target actions

- (IBAction)facebookLogin:(UIButton *)sender 
{    
    [PFFacebookUtils logInWithPermissions:self.facebookPermissions block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        } else if (user.isNew) {
            NSLog(@"User signed up and logged in through Facebook!");
            [self.delegate logInViewController:self didLogInUser:user];
        } else {
            NSLog(@"User logged in through Facebook!");
            [self.delegate logInViewController:self didLogInUser:user];
        }
    }];
    
    return;
}

- (IBAction)manualLogin:(UIButton *)sender 
{
}

- (IBAction)cancel:(id)sender 
{
    [self.delegate logInViewControllerDidCancelLogIn:self];
}

- (void)loginFailed
{
    //TODO: Implement this method. Add notification center.  
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end

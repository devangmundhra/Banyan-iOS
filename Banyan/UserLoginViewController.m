//
//  UserLoginViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserLoginViewController.h"
#import "BanyanAppDelegate.h"

@interface UserLoginViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *backNavigationItem;

@end

@implementation UserLoginViewController
@synthesize cancelButton = _cancelButton;
@synthesize facebookLoginButton = _facebookLoginButton;
@synthesize navigationBar = _navigationBar;
@synthesize backNavigationItem = _backNavigationItem;
@synthesize delegate = _delegate;
@synthesize facebookPermissions = _facebookPermissions;
@synthesize activityIndicator = _activityIndicator;

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
}

- (void)viewDidUnload
{
    [self setFacebookLoginButton:nil];
    [self setNavigationBar:nil];
    [self setBackNavigationItem:nil];
    [self setCancelButton:nil];
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
        [self.activityIndicator stopAnimating]; // Hide loading indicator
        
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:@"Uh oh. The user cancelled the Facebook login." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error" message:[error description] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                [alert show];
            }
        } else if (user.isNew) {
            NSLog(@"User with facebook signed up and logged in!");
            [self.delegate logInViewController:self didLogInUser:user];
        } else {
            NSLog(@"User with facebook logged in!");
            [self.delegate logInViewController:self didLogInUser:user];
        }
    }];
    
    [self.activityIndicator startAnimating]; // Show loading indicator until login is finished
    [self dismissViewControllerAnimated:YES completion:nil];
    return;
}

- (IBAction)cancel:(id)sender 
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end

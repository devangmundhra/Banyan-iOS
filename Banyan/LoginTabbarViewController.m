//
//  LoginTabbarViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginTabbarViewController.h"

@interface LoginTabbarViewController ()

@property (strong, nonatomic) IBOutlet UIToolbar *loginToolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *loginButton;

@end

@implementation LoginTabbarViewController
@synthesize loginToolbar = _loginToolbar;
@synthesize loginButton = _loginButton;
@synthesize module = _module;

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
    // Do any additional setup after loading the view from its nib.
//    CGRect screenRect = [[UIScreen mainScreen] bounds];
//    CGRect viewRect = self.view.bounds;
//    self.view.frame = CGRectMake(0, screenRect.size.height - viewRect.size.height, viewRect.size.width, viewRect.size.height);
    
    self.loginToolbar.barStyle = UIBarStyleBlack;
    self.loginToolbar.translucent = NO;
    
//    self.loginButton.style = UIBarButtonItemStyleDone;
    self.loginButton.target = self.module;
    self.loginButton.action = @selector(login);
}

- (void)viewDidUnload
{
    [self setLoginToolbar:nil];
    [self setLoginButton:nil];
    [self setModule:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end

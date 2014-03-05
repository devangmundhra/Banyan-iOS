//
//  UserLoginViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 3/29/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "UserLoginViewController.h"
#import "TTTAttributedLabel.h"
#import "BanyanAppDelegate.h"
#import "MBProgressHUD.h"

@interface UserLoginViewController (TTTAttributedLabelDelegate) <TTTAttributedLabelDelegate, UIActionSheetDelegate>
@end

@interface UserLoginViewController () <FBLoginViewDelegate>
@property (weak, nonatomic) IBOutlet FBLoginView *fbLoginView;
@property (weak, nonatomic) IBOutlet UILabel *noSharePromiseLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *eulaLabel;

@end

@implementation UserLoginViewController
@synthesize fbLoginView = _fbLoginView;
@synthesize delegate = _delegate;
@synthesize noSharePromiseLabel = _noSharePromiseLabel;

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

    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"Get started!";
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];

    self.noSharePromiseLabel.font = [UIFont fontWithName:@"Roboto-Medium" size:22];
    
    self.eulaLabel.font = [UIFont fontWithName:@"Roboto" size:16];
    self.eulaLabel.textColor = BANYAN_GRAY_COLOR;
    self.eulaLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.eulaLabel.numberOfLines = 0;
    self.eulaLabel.textAlignment = NSTextAlignmentLeft;
    self.eulaLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
    self.eulaLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.eulaLabel.text = @"By logging in, you agree to the terms that govern the use of the Banyan application.";
    NSRange range = [self.eulaLabel.text rangeOfString:@"terms"];
    [self.eulaLabel addLinkToURL:[NSURL URLWithString:@"https://www.banyan.io/terms"] withRange:range];
    self.eulaLabel.delegate = self;

    self.fbLoginView.readPermissions = [NSArray arrayWithObjects: @"email", @"user_about_me", @"user_photos", nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"User Login"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark target actions


- (IBAction)cancel:(id)sender 
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark FBLoginViewDelegate methods
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Registering with Banyan";
    hud.labelFont = [UIFont fontWithName:@"Roboto" size:14];
    __weak MBProgressHUD *whud = hud;
    __weak UserLoginViewController *wself = self;
    [self.delegate loginViewControllerDidLoginWithFacebookUser:user withCompletionBlock:^(bool succeeded, NSError *error) {
        if (!succeeded) {
            [[[UIAlertView alloc] initWithTitle:@"Error when registering with Banyan"
                                        message:@"Sorry for the inconvenience. Please try in a bit"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            [APP_DELEGATE logout];
        }
        [whud hide:YES];
        [wself dismissViewControllerAnimated:YES completion:nil];
    }];
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
        BNLogInfo(@"user cancelled login");
    } else {
        // For simplicity, this sample treats other errors blindly.
        alertTitle  = @"Unknown Error";
        alertMessage = @"Error. Please try again later.";
        BNLogError(@"Unexpected error:%@", error);
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

@implementation UserLoginViewController (TTTAttributedLabelDelegate)

- (void)attributedLabel:(__unused TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url
{
    [[[UIActionSheet alloc] initWithTitle:[url absoluteString] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open Link in Safari", nil), nil] showInView:self.view];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionSheet.title]];
}

@end
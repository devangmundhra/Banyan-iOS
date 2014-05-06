//
//  InvitationHelpViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 3/7/14.
//
//

#import "HelpInfoViewController.h"
#import "MZFormSheetController.h"
#import "UIImage+Create.h"
#import <QuartzCore/QuartzCore.h>

@implementation HelpInfoViewController

@synthesize descriptionTextView = _descriptionTextView;
@synthesize gotitButton = _gotitButton;

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

    [self.gotitButton setStyle:BButtonStyleBootstrapV3];
    [self.gotitButton setType:BButtonTypeSuccess];
    [self.gotitButton.titleLabel setFont:[UIFont fontWithName:@"Roboto" size:16]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"permissions help"];    
}

- (IBAction)gotitButtonPressed:(id)sender
{
    [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"button" label:@"Got it permission" value:nil];
    [self mz_dismissFormSheetControllerAnimated:YES completionHandler:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

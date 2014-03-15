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

@interface HelpInfoViewController ()

@property (weak, nonatomic) IBOutlet UIButton *gotitButton;

@end

@implementation HelpInfoViewController

@synthesize descriptionLabel = _descriptionLabel;
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

    self.gotitButton.layer.cornerRadius = 4.0f;
    self.gotitButton.layer.masksToBounds = YES;
    
    [self.gotitButton.titleLabel setFont:[UIFont fontWithName:@"Roboto" size:16]];
    
    [self.gotitButton setBackgroundImage:[UIImage imageWithColor:BANYAN_LIGHT_GREEN_COLOR
                                                         forRect:self.gotitButton.bounds] forState:UIControlStateNormal];
    [self.gotitButton setBackgroundImage:[UIImage imageWithColor:BANYAN_DARK_GREEN_COLOR
                                                         forRect:self.gotitButton.bounds] forState:UIControlStateHighlighted];
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

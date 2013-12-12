//
//  ProfileViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/26/13.
//
//

#import "ProfileViewController.h"
#import "User.h"
#import "BanyanAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+BNSlidingViewControllerAdditions.h"

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;

@end

@implementation ProfileViewController
@synthesize scrollView = _scrollView;
@synthesize signOutButton = _signOutButton;

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
    self.title = [BNSharedUser currentUser].name;
    
    CGSize screenSize = [UIScreen mainScreen].applicationFrame.size;
    self.scrollView.contentSize = CGSizeMake(screenSize.width,
                                             screenSize.height);
    // Configure the signout button
    [self.signOutButton.titleLabel setFont:[UIFont fontWithName:@"Roboto-Bold" size:18]];
    self.signOutButton.userInteractionEnabled = YES;
    [self.signOutButton setTitleColor:BANYAN_WHITE_COLOR forState:UIControlStateNormal];
    self.signOutButton.showsTouchWhenHighlighted = YES;
    
    CALayer *layer = self.signOutButton.layer;
    [layer setCornerRadius:4.0f];
    [layer setMasksToBounds:YES];
    [layer setBorderWidth:1.0f];
    
    [self.signOutButton setTitle:@"Sign out" forState:UIControlStateNormal];
    [self.signOutButton addTarget:self action:@selector(logoutButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.signOutButton.backgroundColor = BANYAN_RED_COLOR;
    layer.borderColor = BANYAN_RED_COLOR.CGColor;
    [self prepareForSlidingViewController];
}

- (IBAction)logoutButtonPressed:(id)sender
{
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    [delegate logout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

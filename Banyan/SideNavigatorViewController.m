//
//  SideNavigatorViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/25/13.
//
//

#import "SideNavigatorViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIViewController+ECSlidingViewController.h"
#import "SettingsTableViewController.h"
#import "BanyanAppDelegate.h"
#import "FollowingFriendsViewController.h"
#import "ProfileViewController.h"
#import "AboutViewController.h"
#import "StoryListTableViewController.h"
#import "UserVoice.h"

@interface SideNavigatorViewController ()

@property (strong, nonatomic) UIButton *actionButton;

@end

typedef NS_ENUM(NSUInteger, SidePanelOptionLoggedIn) {
    SidePanelOptionLoggedInHome,
    SidePanelOptionLoggedInProfile,
//    SidePanelOptionLoggedInFriends,
    SidePanelOptionLoggedInSettings,
    SidePanelOptionLoggedInFeedback,
    SidePanelOptionLoggedInAbout,
    SidePanelOptionLoggedInMax,
};

typedef NS_ENUM(NSUInteger, SidePanelOptionLoggedOut) {
    SidePanelOptionLoggedOutHome,
    SidePanelOptionLoggedOutSettings,
    SidePanelOptionLoggedOutFeedback,
    SidePanelOptionLoggedOutAbout,
    SidePanelOptionLoggedOutMax,
};

@implementation SideNavigatorViewController

@synthesize actionButton;

#define BACKGROUND_COLOR BANYAN_CLEAR_COLOR
#define SEPERATOR_COLOR BANYAN_DARKBROWN_COLOR
#define FOREGROUND_COLOR BANYAN_LIGHTGRAY_COLOR

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Hamburger menu screen"];
    [self updateSignInOutButtons];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Notifications to handle permission controls
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogInNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogOutNotification
                                               object:nil];
    
    self.tableView.backgroundColor = BACKGROUND_COLOR;
    UIImage *backgroundImage = [UIImage imageNamed:@"slider_background"]; // Image from http://flic.kr/p/7HxPc3
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.tableView.backgroundView = backgroundImageView;
    
    // Assign the header/footer views
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 65)];
    actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [actionButton.titleLabel setFont:[UIFont fontWithName:@"Roboto-Bold" size:18]];
    actionButton.userInteractionEnabled = YES;
    [actionButton setTitleColor:BANYAN_WHITE_COLOR forState:UIControlStateNormal];
    actionButton.showsTouchWhenHighlighted = YES;
    actionButton.backgroundColor = [BANYAN_GREEN_COLOR colorWithAlphaComponent:0.5];

    CALayer *layer = actionButton.layer;
    [layer setCornerRadius:8.0f];
    [layer setMasksToBounds:YES];
    [layer setBorderWidth:1.0f];
    layer.borderColor = BANYAN_GREEN_COLOR.CGColor;

    [view addSubview:actionButton];
    self.tableView.tableHeaderView = view;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.tableView.separatorColor = SEPERATOR_COLOR;
    self.tableView.rowHeight = 40.0f;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) userLoginStatusChanged:(NSNotification *)notification
{
    [self updateSignInOutButtons];
    [self.tableView reloadData];
}

- (void) updateSignInOutButtons
{
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIView *view = self.tableView.tableHeaderView;
    view.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 65);
    if (![BanyanAppDelegate loggedIn]) {
        actionButton.hidden = NO;
        [actionButton setTitle:@"Sign in" forState:UIControlStateNormal];
        [actionButton addTarget:delegate action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
        paraStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        paraStyle.alignment = NSTextAlignmentLeft;

        
        CGSize expectedSize = [actionButton.titleLabel.text boundingRectWithSize:view.frame.size
                                                         options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:18],
                                                                                                                                                   NSParagraphStyleAttributeName: paraStyle}
                                                         context:nil].size;
        
        CGRect frame = view.frame;
        frame.size = expectedSize;
        frame.size.width += 20;
        frame.size.height += 10;
        frame.origin.y = CGRectGetMaxY(view.frame) - frame.size.height -10;
        frame.origin.x = CGRectGetMidX(view.frame) - CGRectGetWidth(frame)/2;
        actionButton.frame = frame;
    } else {
        CGRect frame = view.frame;
        frame.size.height = 25;
        view.frame = frame;
        actionButton.hidden = YES;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if ([BanyanAppDelegate loggedIn])
        return SidePanelOptionLoggedInMax;
    else
        return SidePanelOptionLoggedOutMax;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Side Navigation Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:15];
    cell.textLabel.textColor = FOREGROUND_COLOR;
    
    // Configure the cell...
    if ([BanyanAppDelegate loggedIn]) {
        switch (indexPath.row) {
            case SidePanelOptionLoggedInHome:
                cell.textLabel.text = @"Home";
                break;
            case SidePanelOptionLoggedInProfile:
                cell.textLabel.text = @"Profile";
                break;
//            case SidePanelOptionLoggedInFriends:
//                cell.textLabel.text = @"Friends";
//                break;
            case SidePanelOptionLoggedInSettings:
                cell.textLabel.text = @"Settings";
                break;
            case SidePanelOptionLoggedInFeedback:
                cell.textLabel.text = @"Feedback";
                break;
            case SidePanelOptionLoggedInAbout:
                cell.textLabel.text = @"About Banyan";
                break;
            default:
                break;
        }
    } else {
        switch (indexPath.row) {
            case SidePanelOptionLoggedOutHome:
                cell.textLabel.text = @"Home";
                break;
            case SidePanelOptionLoggedOutSettings:
                cell.textLabel.text = @"Settings";
                break;
            case SidePanelOptionLoggedOutFeedback:
                cell.textLabel.text = @"Feedback";
                break;
            case SidePanelOptionLoggedOutAbout:
                cell.textLabel.text = @"About Banyan";
                break;
            default:
                break;
        }
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = BACKGROUND_COLOR;
    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    backgroundView.backgroundColor = SEPERATOR_COLOR;
    backgroundView.layer.masksToBounds = YES;
    backgroundView.layer.shadowOffset = CGSizeMake(0, 0);
    backgroundView.layer.shadowRadius = 5;
    backgroundView.layer.shadowOpacity = 1;
    backgroundView.layer.shadowPath = [UIBezierPath bezierPathWithRect:cell.bounds].CGPath;
    
    [cell setSelectedBackgroundView:backgroundView];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if ([BanyanAppDelegate loggedIn]) {
        switch (indexPath.row) {
            case SidePanelOptionLoggedInHome:
                self.slidingViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:[[StoryListTableViewController alloc] init]];
                break;
            case SidePanelOptionLoggedInProfile:
                self.slidingViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:[[ProfileViewController alloc] init]];
                break;
//            case SidePanelOptionLoggedInFriends:
//                self.slidingViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:[[FollowingFriendsViewController alloc] init]];
//                break;
            case SidePanelOptionLoggedInSettings:
                self.slidingViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:[[SettingsTableViewController alloc] init]];
                break;
            case SidePanelOptionLoggedInFeedback:
                 [UserVoice presentUserVoiceInterfaceForParentViewController:self.slidingViewController];
                break;
            case SidePanelOptionLoggedInAbout:
                self.slidingViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:[[AboutViewController alloc] init]];
                break;
            default:
                break;
        }
    } else {
        switch (indexPath.row) {
            case SidePanelOptionLoggedOutHome:
                self.slidingViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:[[StoryListTableViewController alloc] init]];
                break;
            case SidePanelOptionLoggedOutSettings:
                self.slidingViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:[[SettingsTableViewController alloc] init]];
                break;
            case SidePanelOptionLoggedOutFeedback:
                [UserVoice presentUserVoiceInterfaceForParentViewController:self.slidingViewController];
                break;
            case SidePanelOptionLoggedOutAbout:
                self.slidingViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:[[AboutViewController alloc] init]];
                break;
            default:
                break;
        }
    }
    
    [self.slidingViewController resetTopViewAnimated:YES];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
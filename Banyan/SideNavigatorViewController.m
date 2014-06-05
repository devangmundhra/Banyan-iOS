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
#import "SideNavigatorTableViewCell.h"
#import "BNNotificationsView.h"
#import "User.h"
#import "AFBanyanAPIClient.h"
#import "NSString+FontAwesome.h"

static NSString *CellIdentifier = @"SideNavigationCell";

@interface SideNavigatorViewController ()

@property (strong, nonatomic) UIButton *actionButton;
@property (nonatomic) BOOL isNotificationsExpanded;
@property (strong, nonatomic) UIView *notificationExpansionView;

@end

typedef NS_ENUM(NSUInteger, SidePanelOptionLoggedIn) {
    SidePanelOptionLoggedInHome,
    SidePanelOptionLoggedInNotifications,
    SidePanelOptionLoggedInProfile,
//    SidePanelOptionLoggedInFriends,
    SidePanelOptionLoggedInSettings,
    SidePanelOptionLoggedInFeedback,
    SidePanelOptionLoggedInAbout,
    SidePanelOptionLoggedInMax,
};

typedef NS_ENUM(NSUInteger, SidePanelOptionLoggedOut) {
    SidePanelOptionLoggedOutHome,
//    SidePanelOptionLoggedOutSettings,
    SidePanelOptionLoggedOutFeedback,
    SidePanelOptionLoggedOutAbout,
    SidePanelOptionLoggedOutMax,
};

@implementation SideNavigatorViewController

@synthesize actionButton = _actionButton;
@synthesize notificationExpansionView = _notificationExpansionView;
@synthesize isNotificationsExpanded;

#define BACKGROUND_COLOR BANYAN_CLEAR_COLOR
#define SEPERATOR_COLOR BANYAN_DARKBROWN_COLOR

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
    [self getNotificationsFromServer];
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
    [self.tableView registerNib:[UINib nibWithNibName:@"SideNavigatorTableViewCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    
    UIImage *backgroundImage = [UIImage imageNamed:@"slider_background"]; // Image from http://flic.kr/p/7HxPc3
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.tableView.backgroundView = backgroundImageView;
    
    // Assign the header/footer views
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 65)];
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.actionButton.titleLabel setFont:[UIFont fontWithName:@"Roboto-Bold" size:18]];
    self.actionButton.userInteractionEnabled = YES;
    [self.actionButton setTitleColor:BANYAN_WHITE_COLOR forState:UIControlStateNormal];
    self.actionButton.showsTouchWhenHighlighted = YES;
    self.actionButton.backgroundColor = [BANYAN_GREEN_COLOR colorWithAlphaComponent:0.5];

    CALayer *layer = self.actionButton.layer;
    [layer setCornerRadius:8.0f];
    [layer setMasksToBounds:YES];
    [layer setBorderWidth:1.0f];
    layer.borderColor = BANYAN_GREEN_COLOR.CGColor;

    [view addSubview:self.actionButton];
    self.tableView.tableHeaderView = view;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.tableView.separatorColor = SEPERATOR_COLOR;
    
    self.isNotificationsExpanded = YES;
    UIActivityIndicatorView *av = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [av startAnimating];
    av.center = self.view.center;
    CGRect frame = av.frame;
    frame.origin.y = 0;
    av.frame = frame;
    self.notificationExpansionView = av;
}

- (UIView *)notificationExpansionView
{
    if (self.isNotificationsExpanded) {
        return _notificationExpansionView;
    } else {
        return nil;
    }
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
        self.actionButton.hidden = NO;
        [self.actionButton setTitle:@"Sign in" forState:UIControlStateNormal];
        [self.actionButton addTarget:delegate action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        
        NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
        paraStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        paraStyle.alignment = NSTextAlignmentLeft;

        
        CGSize expectedSize = [self.actionButton.titleLabel.text boundingRectWithSize:view.frame.size
                                                         options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:18],
                                                                                                                                                   NSParagraphStyleAttributeName: paraStyle}
                                                         context:nil].size;
        
        CGRect frame = view.frame;
        frame.size = expectedSize;
        frame.size.width += 20;
        frame.size.height += 10;
        frame.origin.y = CGRectGetMaxY(view.frame) - frame.size.height -10;
        frame.origin.x = CGRectGetMidX(view.frame) - CGRectGetWidth(frame)/2;
        self.actionButton.frame = frame;
    } else {
        CGRect frame = view.frame;
        frame.size.height = 25;
        view.frame = frame;
        self.actionButton.hidden = YES;
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
    SideNavigatorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"SideNavigatorTableViewCell" owner:self options:nil];
        cell = (SideNavigatorTableViewCell *)[nibs objectAtIndex:0];
    }

    BNSharedUser *currentUser = nil;
    
    cell.arrowLabel.text = [NSString fa_stringForFontAwesomeIcon:FAAngleRight];
    
    // Configure the cell...
    if ([BanyanAppDelegate loggedIn]) {
        switch (indexPath.row) {
            case SidePanelOptionLoggedInHome:
                cell.titleLabel.text = @"Home";
                break;
            case SidePanelOptionLoggedInNotifications:
                cell.titleLabel.text = @"Notifications";
                if (self.isNotificationsExpanded) {
                    cell.arrowLabel.text = [NSString fa_stringForFontAwesomeIcon:FAAngleDown];
                } else {
                    cell.arrowLabel.text = [NSString fa_stringForFontAwesomeIcon:FAAngleUp];
                }
                break;
            case SidePanelOptionLoggedInProfile:
                currentUser = [BNSharedUser currentUser];
                cell.titleLabel.text = currentUser.name;
                break;
//            case SidePanelOptionLoggedInFriends:
//                cell.textLabel.text = @"Friends";
//                break;
            case SidePanelOptionLoggedInSettings:
                cell.titleLabel.text = @"Settings";
                break;
            case SidePanelOptionLoggedInFeedback:
                cell.titleLabel.text = @"Feedback";
                break;
            case SidePanelOptionLoggedInAbout:
                cell.titleLabel.text = @"About Banyan";
                break;
            default:
                break;
        }
    } else {
        switch (indexPath.row) {
            case SidePanelOptionLoggedOutHome:
                cell.titleLabel.text = @"Home";
                break;
            case SidePanelOptionLoggedOutFeedback:
                cell.titleLabel.text = @"Feedback";
                break;
            case SidePanelOptionLoggedOutAbout:
                cell.titleLabel.text = @"About Banyan";
                break;
            default:
                break;
        }
    }
    if (![BanyanAppDelegate loggedIn] || indexPath.row != SidePanelOptionLoggedInNotifications) {
        [cell setSelectionColor:SEPERATOR_COLOR];
        [cell setExpansionView:nil];
    } else {
        [cell setSelectionColor:BANYAN_CLEAR_COLOR];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setExpansionView:self.notificationExpansionView];
    }
    cell.backgroundColor = BACKGROUND_COLOR;

    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![BanyanAppDelegate loggedIn] || indexPath.row != SidePanelOptionLoggedInNotifications) {
        return SideNavigatorTableViewCellHeight;
    } else {
        return SideNavigatorTableViewCellHeight + CGRectGetHeight(self.notificationExpansionView.bounds);
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Navigation logic may go here. Create and push another view controller.
    if ([BanyanAppDelegate loggedIn]) {
        switch (indexPath.row) {
            case SidePanelOptionLoggedInHome:
                self.slidingViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:[[StoryListTableViewController alloc] init]];
                break;
            case SidePanelOptionLoggedInNotifications:
                self.isNotificationsExpanded = !self.isNotificationsExpanded;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                break;
            case SidePanelOptionLoggedInProfile:
                self.slidingViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:[[ProfileViewController alloc] init]];
                break;
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
    
    if (![BanyanAppDelegate loggedIn] || indexPath.row != SidePanelOptionLoggedInNotifications) {
        [self.slidingViewController resetTopViewAnimated:YES];
    }
}

- (void) getNotificationsFromServer
{
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser) {
        return;
    }
    // Fetch the information and update the UI with the information
    [[AFBanyanAPIClient sharedClient] getPath:[NSString stringWithFormat:@"users/%@/notifications?format=json", currentUser.userId]
                                   parameters:nil
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSArray *notifications = [responseObject objectForKey:@"objects"];
                                          if (notifications.count == 0) {
                                              UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, CGRectGetWidth(self.view.bounds)-40, 15)];
                                              label.text = @"No new notifications";
                                              label.font = [UIFont fontWithName:@"Roboto" size:12];
                                              label.textColor = BANYAN_DARKBROWN_COLOR;
                                              self.notificationExpansionView = label;
                                          } else {
                                              BNNotificationsView *view = [[BNNotificationsView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), notifications.count*BNNotificationsTableViewCellHeight)];
                                              view.notifications = notifications;
                                              self.notificationExpansionView = view;
                                          }
                                          [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:SidePanelOptionLoggedInNotifications inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                                      }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, CGRectGetWidth(self.view.bounds)-40, 15)];
                                          label.text = @"Error in getting the latest notifications";
                                          label.font = [UIFont fontWithName:@"Roboto" size:12];
                                          label.textColor = BANYAN_RED_COLOR;
                                          self.notificationExpansionView = label;
                                          [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:SidePanelOptionLoggedInNotifications inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                                          [BNMisc sendGoogleAnalyticsError:error inAction:@"Fetching notifications" isFatal:NO];
                                      }];
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
//
//  SideNavigatorViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/25/13.
//
//

#import "SideNavigatorViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "BNFeedbackViewController.h"
#import "UIViewController+JASidePanel.h"
#import "SettingsTableViewController.h"
#import "BNSidePanelController.h"
#import "BanyanAppDelegate.h"
#import "FollowingFriendsViewController.h"
#import "ProfileViewController.h"
#import "AboutViewController.h"

@interface SideNavigatorViewController ()

@end

@implementation SideNavigatorViewController


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
    
    [self updateSignInOutButtons];
    
    // Notifications to handle permission controls
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogInNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogOutNotification
                                               object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    self.tableView.backgroundColor = BANYAN_DARKBROWN_COLOR;
    self.tableView.separatorColor = BANYAN_BROWN_COLOR;
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
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 65)];
    view.backgroundColor = BANYAN_DARKBROWN_COLOR;
    
    
    if (![BanyanAppDelegate loggedIn]) {
        UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [actionButton.titleLabel setFont:[UIFont fontWithName:@"Roboto-Bold" size:18]];
        actionButton.userInteractionEnabled = YES;
        [actionButton setTitleColor:BANYAN_WHITE_COLOR forState:UIControlStateNormal];
        actionButton.showsTouchWhenHighlighted = YES;
        
        CALayer *layer = actionButton.layer;
        [layer setCornerRadius:8.0f];
        [layer setMasksToBounds:YES];
        [layer setBorderWidth:1.0f];
        
        [view addSubview:actionButton];
        
        [actionButton setTitle:@"Sign in" forState:UIControlStateNormal];
        [actionButton addTarget:delegate action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        actionButton.backgroundColor = [BANYAN_GREEN_COLOR colorWithAlphaComponent:0.5];
        layer.borderColor = BANYAN_GREEN_COLOR.CGColor;
        
        CGSize expectedSize = [actionButton.titleLabel.text sizeWithFont:[UIFont fontWithName:@"Roboto-Bold" size:18] constrainedToSize:view.frame.size];
        
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
    }
    
    self.tableView.tableHeaderView = view;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
        return 6;
    else
        return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Side Navigation Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:15];
    cell.textLabel.textColor = BANYAN_LIGHTGRAY_COLOR;
    
    // Configure the cell...
    if ([BanyanAppDelegate loggedIn]) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Home";
                break;
            case 1:
                cell.textLabel.text = @"Profile";
                break;
            case 2:
                cell.textLabel.text = @"Friends";
                break;
            case 3:
                cell.textLabel.text = @"Settings";
                break;
            case 4:
                cell.textLabel.text = @"Feedback";
                break;
            case 5:
                cell.textLabel.text = @"About";
                break;
            default:
                break;
        }
    } else {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Home";
                break;
            case 1:
                cell.textLabel.text = @"Settings";
                break;
            case 2:
                cell.textLabel.text = @"Feedback";
                break;
            case 3:
                cell.textLabel.text = @"About";
                break;
            default:
                break;
        }
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = BANYAN_DARKBROWN_COLOR;
    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    backgroundView.backgroundColor = BANYAN_BROWN_COLOR;
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
            case 0:
                self.sidePanelController.centerPanel = ((BanyanAppDelegate *)[[UIApplication sharedApplication] delegate]).storyListTableViewController;
                break;
            case 1:
                self.sidePanelController.centerPanel = [[UINavigationController alloc] initWithRootViewController:[[ProfileViewController alloc] init]];
                break;
            case 2:
                self.sidePanelController.centerPanel = [[UINavigationController alloc] initWithRootViewController:[[FollowingFriendsViewController alloc] init]];
                break;
            case 3:
                self.sidePanelController.centerPanel = [[UINavigationController alloc] initWithRootViewController:[[SettingsTableViewController alloc] init]];
                break;
            case 4:
                self.sidePanelController.centerPanel = [[UINavigationController alloc] initWithRootViewController:[[BNFeedbackViewController alloc] init]];
                break;
            case 5:
                self.sidePanelController.centerPanel = [[UINavigationController alloc] initWithRootViewController:[[AboutViewController alloc] init]];
                break;
            default:
                break;
        }
    } else {
        switch (indexPath.row) {
            case 0:
                self.sidePanelController.centerPanel = ((BanyanAppDelegate *)[[UIApplication sharedApplication] delegate]).storyListTableViewController;
                break;
            case 1:
                self.sidePanelController.centerPanel = [[UINavigationController alloc] initWithRootViewController:[[SettingsTableViewController alloc] init]];
                break;
            case 2:
                self.sidePanelController.centerPanel = [[UINavigationController alloc] initWithRootViewController:[[BNFeedbackViewController alloc] init]];
                break;
            case 3:
                self.sidePanelController.centerPanel = [[UINavigationController alloc] initWithRootViewController:[[AboutViewController alloc] init]];
                break;
            default:
                break;
        }
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
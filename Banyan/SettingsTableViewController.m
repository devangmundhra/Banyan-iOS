//
//  SettingsTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/1/12.
//
//

#import "SettingsTableViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface SettingsTableViewController ()

@end

typedef enum {
    SettingsTableViewProfileSection = 0,
    SettingsTableViewSocialSection,
    SettingsTableViewSettingsSection,
    SettingsTableViewAboutSection,
} SettingsTableViewSection;

@implementation SettingsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"Settings";
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.clearsSelectionOnViewWillAppear = YES;    
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
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 55)];
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [actionButton.titleLabel setFont:[UIFont fontWithName:@"Roboto-Bold" size:18]];
    actionButton.userInteractionEnabled = YES;
    
    CALayer *layer = actionButton.layer;
    [layer setCornerRadius:5.0f];
    [layer setMasksToBounds:YES];
    [layer setBorderWidth: 1.0f];

    [view addSubview:actionButton];
    
    CGRect frame = view.frame;
    frame.origin.x += 20;
    frame.size.width -= 40;
    frame.size.height = 40;
    actionButton.frame = frame;
    self.tableView.tableFooterView = view;

    if (![BanyanAppDelegate loggedIn]) {
        [actionButton setTitle:@"Sign in" forState:UIControlStateNormal];
        [actionButton setBackgroundColor:BANYAN_GREEN_COLOR];
        [actionButton addTarget:delegate action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        layer.borderColor = BANYAN_DARK_GREEN_COLOR.CGColor;
    } else {
        [actionButton setTitle:@"Sign out" forState:UIControlStateNormal];
        [actionButton setBackgroundColor:BANYAN_RED_COLOR];
        [actionButton addTarget:delegate action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (![BanyanAppDelegate loggedIn])
        return 1;
    else
        return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (![BanyanAppDelegate loggedIn])
        return 2;
    
    switch (section) {
        case SettingsTableViewProfileSection:
            return 2;
            break;
        
        case SettingsTableViewSocialSection:
            return 1;
            break;
            
        case SettingsTableViewSettingsSection:
            return 1;
            break;
            
        case SettingsTableViewAboutSection:
            return 2;
            break;
            
        default:
            return 0;
            break;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (![BanyanAppDelegate loggedIn])
        return @"About";
    
    switch (section) {
        case SettingsTableViewProfileSection:
            return @"Profile";
            break;
            
        case SettingsTableViewSocialSection:
            return @"Social";
            break;
            
        case SettingsTableViewSettingsSection:
            return @"Settings";
            break;
            
        case SettingsTableViewAboutSection:
            return @"About";
            break;
            
        default:
            return nil;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Settings Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if (![BanyanAppDelegate loggedIn]) {
        cell.textLabel.text = [self textForAboutSectionAtRow:indexPath.row];
        
        if (!(indexPath.row == SettingsAboutSectionFeedback))
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        switch (indexPath.section) {
            case SettingsTableViewProfileSection:
                cell.textLabel.text = [self textForProfileSectionAtRow:indexPath.row];
                break;
                
            case SettingsTableViewSocialSection:
                cell.textLabel.text = [self textForSocialSectionAtRow:indexPath.row];
                break;
                
            case SettingsTableViewSettingsSection:
                cell.textLabel.text = [self textForSettingsSectionAtRow:indexPath.row];
                break;
                
            case SettingsTableViewAboutSection:
                cell.textLabel.text = [self textForAboutSectionAtRow:indexPath.row];
                break;
                
            default:
                cell.textLabel.text = @"Undefined";
                break;
        }
        if (!(indexPath.section == SettingsAboutSectionAbout && indexPath.row == SettingsAboutSectionFeedback))
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }

    cell.textLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:18];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Navigation logic may go here. Create and push another view controller.
    if (![BanyanAppDelegate loggedIn]) {
        [self actionForAboutSectionAtRow:indexPath.row];
        return;
    }
    
    switch (indexPath.section) {
        case SettingsTableViewProfileSection:
            [self actionForProfileSectionAtRow:indexPath.row];
            break;
            
        case SettingsTableViewSocialSection:
            [self actionForSocialSectionAtRow:indexPath.row];
            break;
            
        case SettingsTableViewSettingsSection:
            [self actionForSettingsSectionAtRow:indexPath.row];
            break;
            
        case SettingsTableViewAboutSection:
            [self actionForAboutSectionAtRow:indexPath.row];
            break;
            
        default:
            break;
    }
    
}

# pragma mark Profile Section
typedef enum {
    SettingsProfileSectionMyProfile = 0,
    SettingsProfileSectionEditProfile = 1,
} SettingsProfileSection;

- (NSString *) textForProfileSectionAtRow:(NSInteger)row
{
    switch (row) {
        case SettingsProfileSectionMyProfile:
            return @"My Profile";
            break;
        case SettingsProfileSectionEditProfile:
            return @"Edit Profile";
            break;
            
        default:
            assert(false);
            break;
    }
}

- (void) actionForProfileSectionAtRow:(NSInteger) row
{
    switch (row) {
        case SettingsProfileSectionMyProfile:
            break;
        case SettingsProfileSectionEditProfile:
            break;
            
        default:
            break;
    }
}

# pragma mark Social Section
typedef enum {
    SettingsSocialSectionFindFriends = 0,
} SettingsSocialSection;

- (NSString *) textForSocialSectionAtRow:(NSInteger)row
{
    switch (row) {
        case SettingsSocialSectionFindFriends:
            return @"Find Friends";
            break;
            
        default:
            assert(false);
            break;
    }
}

- (void) actionForSocialSectionAtRow:(NSInteger) row
{
    FollowingFriendsViewController *findFriendsVc = nil;
    switch (row) {
            break;
        case SettingsSocialSectionFindFriends:
            findFriendsVc = [[FollowingFriendsViewController alloc] initWithStyle:UITableViewStylePlain];
            [self.navigationController pushViewController:findFriendsVc animated:YES];
            break;
            
        default:
            break;
    }
}

# pragma mark Settings Section
typedef enum {
    SettingsSettingsSectionNotifications = 0,
    SettingsSettingsSectionHighResImage
} SettingsSettingsSection;

- (NSString *) textForSettingsSectionAtRow:(NSInteger)row
{
    switch (row) {
        case SettingsSettingsSectionNotifications:
            return @"Notifications";
            break;
        case SettingsSettingsSectionHighResImage:
            return @"High Res Images";
            break;
            
        default:
            assert(false);
            break;
    }
}

- (void) actionForSettingsSectionAtRow:(NSInteger) row
{
    switch (row) {
            
        default:
            break;
    }
}

# pragma mark About Section
typedef enum {
    SettingsAboutSectionAbout = 0,
    SettingsAboutSectionFeedback,
    SettingsAboutSectionLegal
} SettingsAboutSection;

- (NSString *) textForAboutSectionAtRow:(NSInteger)row
{
    switch (row) {
        case SettingsAboutSectionAbout:
            return @"About";
            break;
        case SettingsAboutSectionFeedback:
            return @"Feedback";
            break;
        case SettingsAboutSectionLegal:
            return @"Legal";
            break;
            
        default:
            assert(false);
            break;
    }
}

- (void) actionForAboutSectionAtRow:(NSInteger) row
{
    switch (row) {
        case SettingsAboutSectionAbout:
            break;
        case SettingsAboutSectionFeedback:
//            [TestFlight openFeedbackView];
            break;
        case SettingsAboutSectionLegal:
            break;
            
        default:
            break;
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

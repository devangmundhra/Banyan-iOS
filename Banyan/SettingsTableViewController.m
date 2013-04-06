//
//  SettingsTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/1/12.
//
//

#import "SettingsTableViewController.h"

@interface SettingsTableViewController ()

@end

typedef enum {
    SettingsTableViewAccountSection = 0,
} SettingsTableViewSections;

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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) userLoginStatusChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case SettingsTableViewAccountSection:
            if ([PFUser currentUser])
                return 3; // My Stories, Find Friends, Sign Out
            else
                return 1; // Sign In
            break;
            
        default:
            return 0;
            break;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SettingsTableViewAccountSection:
            return @"Account Information";
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
    switch (indexPath.section) {
        case SettingsTableViewAccountSection:
            cell.textLabel.text = [self textForAccountInfoSectionAtRow:indexPath.row];
            break;
            
        default:
            cell.textLabel.text = @"Undefined";
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Navigation logic may go here. Create and push another view controller.
    switch (indexPath.section) {
        case SettingsTableViewAccountSection:
            [self actionForAccountInfoSectionAtRow:indexPath.row];
            break;
            
        default:
            break;
    }
}

# pragma mark Account Information Section
typedef enum {
    SettingsTableViewControllerAccountInfoMyStories = 0,
    SettingsTableViewControllerAccountInfoSectionMyFriends = 1,
    SettingsTableViewControllerAccountInfoSectionSignOut = 2,
} SettingsTableViewControllerAccountInfoSection;

- (NSString *) textForAccountInfoSectionAtRow:(NSInteger)row
{
    if (![PFUser currentUser]) {
        return @"Sign In";
    }
    switch (row) {
        case SettingsTableViewControllerAccountInfoMyStories:
            return @"My Stories";
            break;
        case SettingsTableViewControllerAccountInfoSectionMyFriends:
            return @"Find Friends";
            break;
        case SettingsTableViewControllerAccountInfoSectionSignOut:
            return @"Sign Out";
            break;
            
        default:
            assert(false);
            break;
    }
}

- (void) actionForAccountInfoSectionAtRow:(NSInteger) row
{
    FollowingFriendsViewController *findFriendsVc = nil;
    
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (![PFUser currentUser]) {
        [delegate login];
        return;
    }
    switch (row) {
        case SettingsTableViewControllerAccountInfoMyStories:
            NSLog(@"My Stories");
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case SettingsTableViewControllerAccountInfoSectionMyFriends:
            findFriendsVc = [[FollowingFriendsViewController alloc] initWithStyle:UITableViewStylePlain];
            [self.navigationController pushViewController:findFriendsVc animated:YES];
            break;
        case SettingsTableViewControllerAccountInfoSectionSignOut:
            [delegate logout];
            [self.navigationController popViewControllerAnimated:YES];
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

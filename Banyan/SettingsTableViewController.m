//
//  SettingsTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/1/12.
//
//

#import "SettingsTableViewController.h"
#import "User.h"

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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
            if ([User currentUser])
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
    static NSString *CellIdentifier = @"Cell";
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
    if (![User currentUser]) {
        return @"Sign In";
    }
    switch (row) {
        case 0:
            return @"My Stories";
            break;
        case 1:
            return @"Find Friends";
            break;
        case 2:
            return @"Sign Out";
            break;
            
        default:
            assert(false);
            break;
    }
}

- (void) actionForAccountInfoSectionAtRow:(NSInteger) row
{
    BanyanAppDelegate *delegate = (BanyanAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (![User currentUser]) {
        [delegate.userManagementModule login];
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    switch (row) {
        case 0:
            NSLog(@"My Stories");
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case 1:
            NSLog(@"Find Friends");
            [self.navigationController popViewControllerAnimated:YES];
            break;
        case 2:
            [delegate.userManagementModule logout];
            [self.navigationController popViewControllerAnimated:YES];
            break;
            
        default:
            break;
    }
}

@end

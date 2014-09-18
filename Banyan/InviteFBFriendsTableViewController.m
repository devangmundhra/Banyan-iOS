//
//  InviteFBFriendsTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 4/25/14.
//
//

#import "InviteFBFriendsTableViewController.h"
#import "BNLabel.h"
#import "User.h"

static NSString *CellIdentifier = @"InviteFriendCell";

@interface InviteFBFriendsTableViewController ()  <UISearchBarDelegate, UISearchDisplayDelegate, InviteFriendCellDelegate>
@property (nonatomic, strong) NSArray *listContacts;
@property (nonatomic, strong) NSMutableArray *filteredListContacts;
@property (strong, nonatomic) NSMutableArray *contactIndex;

@property (nonatomic) BOOL allViewers;
@property (nonatomic, strong) NSMutableArray *selectedViewerContacts;

@property (nonatomic) BOOL allContributors;
@property (nonatomic, strong) NSMutableArray *selectedContributorContacts;
@end

@implementation InviteFBFriendsTableViewController
@synthesize listContacts = _listContacts;
@synthesize filteredListContacts = _filteredListContacts;
@synthesize selectedViewerContacts = _selectedViewerContacts;
@synthesize selectedContributorContacts = _selectedContributorContacts;
@synthesize delegate = _delegate;
@synthesize contactIndex = _contactIndex;

- (id)initWithViewerPermissions:(BNPermissionsObject *)viewerPermission contributorPermission:(BNPermissionsObject *)contributorPermission
{
    self = [super initWithNibName:@"InviteFBFriendsTableViewController" bundle:nil];
    if (self) {
        // Custom initialization
        
        BNSharedUser *currentUser = [BNSharedUser currentUser];
        NSAssert(currentUser, @"No Current user available when modifying story");
        NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                        currentUser.name, @"name",
                                        currentUser.facebookId, @"id", nil];
        
        self.selectedViewerContacts = [NSMutableArray arrayWithArray:viewerPermission.inviteeList.facebookFriends];
        self.selectedContributorContacts = [NSMutableArray arrayWithArray:contributorPermission.inviteeList.facebookFriends];
        
        if ([viewerPermission.inviteeList.isPublic boolValue] || [viewerPermission.inviteeList.allFacebookFriendsOf containsObject:selfInvitation]) {
            self.allViewers = YES;
        } else {
            self.allViewers = NO;
        }
        
        if ([contributorPermission.inviteeList.isPublic boolValue]) {
            self.allContributors = YES;
        } else {
            self.allContributors = NO;
        }
    }
    return self;
}

- (void)setListContacts:(NSArray *)listContacts
{
    if (listContacts == _listContacts)
        return;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    _listContacts = [listContacts sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

- (void)setContactIndex
{
    // Create the index
    if (!_contactIndex)
        _contactIndex = [[NSMutableArray alloc] init];
    
    for (NSDictionary *friend in self.listContacts)
    {
        // Get the first character of each name
        unichar alphabet = [[friend objectForKey:@"name"] characterAtIndex:0];
        NSString *uniChar = [NSString stringWithCharacters:&alphabet length:1];
        // add each letter to the index array
        if (![_contactIndex containsObject:uniChar]) {
            [_contactIndex addObject:uniChar];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.searchDisplayController.searchBar.placeholder = @"Search for a friend";
    self.searchDisplayController.delegate = self;
    self.searchDisplayController.searchResultsDataSource = self;
    self.searchDisplayController.searchResultsDelegate = self;
    self.searchDisplayController.displaysSearchBarInNavigationBar = YES;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"InviteFriendCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    self.searchDisplayController.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tableView.scrollEnabled = YES;
    
    BNLabel *headerLabel = [[BNLabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 54)];
    headerLabel.numberOfLines = 0;
    headerLabel.textEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.text = @"Click on the read and write symbols to select the kind of permission for a friend.";
    headerLabel.font = [UIFont fontWithName:@"Roboto" size:14];
    headerLabel.textColor = BANYAN_BROWN_COLOR;
    self.tableView.tableHeaderView = headerLabel;
    self.tableView.tableFooterView = nil;
    
    // Load the facebook friends list from cache
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *facebookFriends = [userDefaults arrayForKey:BNUserDefaultsMyFacebookFriends];
    if (facebookFriends.count) {
        self.listContacts = facebookFriends;
        [self setContactIndex];
    }
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(loadFacebookFriendsListAndRefresh:) forControlEvents:UIControlEventValueChanged];
    refreshControl.tintColor = BANYAN_GREEN_COLOR;
    self.refreshControl = refreshControl;
    
    [self.refreshControl beginRefreshing];
    [self loadFacebookFriendsListAndRefresh:self];
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneInviting:)]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Facebook Invitation Screen"];
}

- (IBAction)loadFacebookFriendsListAndRefresh:(id)sender
{
    __weak typeof(self) wself = self;
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            NSArray *array = [result objectForKey:@"data"];
            if (array.count != 0) {
                wself.listContacts = array;
                [wself setContactIndex];
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:array forKey:BNUserDefaultsMyFacebookFriends];
                [userDefaults synchronize];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Cannot get friend list"
                                        message:@"There was an error in fetching your list of friends from facebook.\rPlease try again in a bit" delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            [BNMisc sendGoogleAnalyticsError:error inAction:@"Fetching facebook friends" isFatal:NO];
        }
        [wself.refreshControl endRefreshing];
        wself.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Load friends from facebook"];
        if (wself.searchDisplayController.isActive) {
            if (!wself.listContacts.count) {
                [wself.searchDisplayController setActive:NO animated:YES];
            }
        }
        [wself.tableView reloadData];
    }];
}

#pragma mark - Table view data source
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (self.searchDisplayController.isActive)
        return nil;
	else
        return self.contactIndex;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.searchDisplayController.isActive)
        return nil;
	else
        return [self.contactIndex objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}

- (NSArray *)getContactsForSection:(NSInteger)section
{
    NSString *alphabet = [self.contactIndex objectAtIndex:section];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name beginswith[c] %@", alphabet];
    NSArray *contacts = [self.listContacts filteredArrayUsingPredicate:predicate];
    return contacts;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.searchDisplayController.isActive)
        return 1;
	else
        return [self.contactIndex count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        return [self.filteredListContacts count];
    }
	else
	{
        NSArray *contacts = [self getContactsForSection:section];
        return [contacts count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    InviteFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"InviteFriendCell" owner:self options:nil];
        cell = (InviteFriendCell *)[nibs objectAtIndex:0];
    }
    
    // Configure the cell...
    NSDictionary *friend = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        friend = [self.filteredListContacts objectAtIndex:indexPath.row];
    } else {
        NSArray *contacts = [self getContactsForSection:indexPath.section];
        friend = [contacts objectAtIndex:indexPath.row];
    }
    
    cell.delegate = self;
    
    // Set the name
    [cell setFriend:friend];
    
    // Set/disable write button. If write is allowed, read is automatically allowed.
    
    // Set/disable read button
    [cell enableReadButton:!self.allViewers && ![self hasWritePermission:friend]];
    [cell enableWriteButton:!self.allContributors];
    
    [cell canRead:[self hasReadPermission:friend]];
    [cell canWrite:[self hasWritePermission:friend]];
    
    return cell;
}

- (BOOL) hasReadPermission:(NSDictionary *)friend
{
    if (self.allContributors || self.allViewers)
        return TRUE;
    
    NSAssert(self.selectedViewerContacts, @"No permission object for selected viewers");
    
    return [self.selectedViewerContacts containsObject:friend] || [self.selectedContributorContacts containsObject:friend];
}

- (BOOL) hasWritePermission:(NSDictionary *)friend
{
    if (self.allContributors)
        return TRUE;
    
    NSAssert(self.selectedContributorContacts, @"No permission object for selected contributors");
    
    
    return [self.selectedContributorContacts containsObject:friend];
}

# pragma mark InviteFriendCellDelegate methods
- (void)inviteFriendCellReadButtonTapped:(InviteFriendCell *)cell
{
    NSIndexPath * myIndexPath = nil;
    NSDictionary *friend = nil;
    
    if (self.searchDisplayController.isActive) {
        myIndexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:cell];
        friend = [self.filteredListContacts objectAtIndex:myIndexPath.row];
    } else {
        myIndexPath = [self.tableView indexPathForCell:cell];
        NSArray *contacts = [self getContactsForSection:myIndexPath.section];
        friend = [contacts objectAtIndex:myIndexPath.row];
    }
    
    // Toggle read permission
    if ([self hasReadPermission:friend]) {
        [self.selectedViewerContacts removeObject:friend];
    } else {
        [self.selectedViewerContacts addObject:friend];
    }
    [cell canRead:[self hasReadPermission:friend]];
    if (self.searchDisplayController.isActive) {
        // Scroll to the selected cell
        [self.searchDisplayController setActive:NO animated:YES];
        [self.tableView scrollToRowAtIndexPath:[self indexPathForFriendInTableView:friend]
                              atScrollPosition:UITableViewScrollPositionNone
                                      animated:NO];
    }
}

- (void)inviteFriendCellWriteButtonTapped:(InviteFriendCell *)cell
{
    NSIndexPath * myIndexPath = nil;
    NSDictionary *friend = nil;
    
    if (self.searchDisplayController.isActive) {
        myIndexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:cell];
        friend = [self.filteredListContacts objectAtIndex:myIndexPath.row];
    } else {
        myIndexPath = [self.tableView indexPathForCell:cell];
        NSArray *contacts = [self getContactsForSection:myIndexPath.section];
        friend = [contacts objectAtIndex:myIndexPath.row];
    }
    
    // Toggle write permission
    if ([self hasWritePermission:friend]) {
        [self.selectedContributorContacts removeObject:friend];
    } else {
        [self.selectedContributorContacts addObject:friend];
    }
    [cell canWrite:[self hasWritePermission:friend]];
    if (!self.allViewers)
        [cell canRead:[self hasReadPermission:friend]];
    [cell enableReadButton:![self hasWritePermission:friend]&&!self.allViewers];
    if (self.searchDisplayController.isActive) {
        // Scroll to the selected cell
        [self.searchDisplayController setActive:NO animated:YES];
        [self.tableView scrollToRowAtIndexPath:[self indexPathForFriendInTableView:friend]
                              atScrollPosition:UITableViewScrollPositionNone
                                      animated:NO];
    }
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    InviteFriendCell *cell = (InviteFriendCell *)[tableView cellForRowAtIndexPath:indexPath];
    [self inviteFriendCellWriteButtonTapped:cell];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.searchDisplayController.isActive) {
        // Scroll to the friend that was picked
        NSDictionary *friend = [self.filteredListContacts objectAtIndex:indexPath.row];
        [self.tableView scrollToRowAtIndexPath:[self indexPathForFriendInTableView:friend] atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}

- (IBAction)doneInviting:(UIBarButtonItem *)sender
{
    [self.delegate invitedFBFriendsViewController:self
                       finishedInvitingForViewers:self.selectedViewerContacts
                                     contributors:self.selectedContributorContacts];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSIndexPath *)indexPathForFriendInTableView:(NSDictionary *)friend
{
    unichar alphabet = [[friend objectForKey:@"name"] characterAtIndex:0];
    NSString *uniChar = [NSString stringWithCharacters:&alphabet length:1];
    NSUInteger section = [self.contactIndex indexOfObject:uniChar];
    NSArray *contacts = [self getContactsForSection:section];
    NSUInteger row = [contacts indexOfObject:friend];
    return [NSIndexPath indexPathForRow:row inSection:section];
}

#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	/*
	 Update the filtered array based on the search text and scope.
	 */
	
	[self.filteredListContacts removeAllObjects]; // First clear the filtered array.
	
    NSPredicate *resultPredicate = [NSPredicate
                                    predicateWithFormat:@"name contains[cd] %@",
                                    searchText];
    self.filteredListContacts = [[self.listContacts filteredArrayUsingPredicate:resultPredicate] mutableCopy];
}

#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    [self.tableView reloadSectionIndexTitles]; // To hide the section index titles
    [controller.searchResultsTableView reloadData];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    [self.tableView reloadSectionIndexTitles]; // To show the section index titles
    [self.tableView reloadData];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end

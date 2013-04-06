//
//  InvitedTableViewController.m
//  Storied
//
//  Created by Devang Mundhra on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InvitedTableViewController.h"
#import "BanyanAppDelegate.h"

@interface InvitedTableViewController ()

@property (nonatomic, strong) NSArray *listContacts;
@property (nonatomic, strong) NSMutableArray *filteredListContacts;
@property (strong, nonatomic) NSMutableArray *contactIndex;
@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchDisplayController;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic) BOOL allViewers;
@property (nonatomic, strong) NSMutableArray *selectedViewerContacts;

@property (nonatomic) BOOL allContributors;
@property (nonatomic, strong) NSMutableArray *selectedContributorContacts;

@end

@implementation InvitedTableViewController
@synthesize listContacts = _listContacts;
@synthesize filteredListContacts = _filteredListContacts;
@synthesize selectedViewerContacts = _selectedViewerContacts;
@synthesize selectedContributorContacts = _selectedContributorContacts;
@synthesize delegate = _delegate;
@synthesize contactIndex = _contactIndex;
@synthesize searchDisplayController;
@synthesize searchBar;

// When initialized from storyboard
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {

    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
         searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
         searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
         searchDisplayController.delegate = self;
         searchDisplayController.searchResultsDataSource = self;

        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneInviting:)]];
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];
    }
    return self;
}

- (id)initWithViewerPermissions:(NSDictionary *)viewerPermission contributorPermission:(NSDictionary *)contributorPermission
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        searchDisplayController.delegate = self;
        searchDisplayController.searchResultsDataSource = self;
        
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneInviting:)]];
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];
        
        if (![[viewerPermission objectForKey:kBNStoryPrivacyScope] isEqualToString:kBNStoryPrivacyScopeInvited]) {
            self.allViewers = YES;
            self.selectedViewerContacts = nil;
        } else {
            self.allViewers = NO;
            self.selectedViewerContacts = [NSMutableArray arrayWithArray:[[viewerPermission objectForKey:kBNStoryPrivacyScopeInvited]
                                                                          objectForKey:kBNStoryPrivacyInvitedFacebookFriends]];
        }
        if (![[contributorPermission objectForKey:kBNStoryPrivacyScope] isEqualToString:kBNStoryPrivacyScopeInvited]) {
            self.allContributors = YES;
            self.selectedContributorContacts = nil;
        } else {
            self.allContributors = NO;
            self.selectedContributorContacts = [NSMutableArray arrayWithArray:[[contributorPermission objectForKey:kBNStoryPrivacyScopeInvited]
                                                                          objectForKey:kBNStoryPrivacyInvitedFacebookFriends]];
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
        char alphabet = [[friend objectForKey:@"name"] characterAtIndex:0];
        NSString *uniChar = [NSString stringWithFormat:@"%c", alphabet];
        // add each letter to the index array
        if (![_contactIndex containsObject:uniChar])
            [_contactIndex addObject:uniChar];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"InviteFriendCell" bundle:nil] forCellReuseIdentifier:@"InviteFriendCell"];
    [[self tableView] setTableHeaderView:searchBar];
    self.searchDisplayController.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tableView.scrollEnabled = YES;
    self.navigationItem.title = @"Invitations";

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *array = [defaults objectForKey:BNUserDefaultsFacebookFriends];
    self.listContacts = array;
    [self setContactIndex];
    
    [TestFlight passCheckpoint:@"Invitation view loaded"];
}


- (void)viewDidUnload
{
    self.listContacts = nil;
    self.filteredListContacts = nil;
    self.delegate = nil;
    self.contactIndex = nil;
    self.searchDisplayController = nil;
    self.searchBar = nil;
    self.selectedContributorContacts = nil;
    self.selectedViewerContacts = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Table view data source
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return nil;
    else
        return self.contactIndex;
//    TO BE ADDED WHEN ADDING SEARCH BAR
//        return [[NSArray arrayWithObject:UITableViewIndexSearch] arrayByAddingObjectsFromArray:self.contactIndex];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return nil;
	else
        return [self.contactIndex objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (index == 0)
        [self.tableView scrollRectToVisible:self.tableView.tableHeaderView.frame animated:NO];
    return index-1;
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
    if (tableView == self.searchDisplayController.searchResultsTableView)
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
    static NSString *CellIdentifier = @"InviteFriendCell";
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
    [cell setName:[friend objectForKey:@"name"]];

    // Set/disable write button. If write is enabled, read is automatically enabled.
    
    // Set/disable read button
    [cell disableReadButton:!self.allViewers];
    [cell disableWriteButton:!self.allContributors];
    
    [cell canRead:[self hasReadPermission:friend]];
    [cell canWrite:[self hasWritePermission:friend]];

    return cell;
}

- (BOOL) hasReadPermission:(NSDictionary *)friend
{
    if (self.allContributors || self.allViewers)
        return TRUE;
    
    if (HAVE_ASSERTS)
        assert(self.selectedViewerContacts);
    
    return [self.selectedViewerContacts containsObject:friend];
}

- (BOOL) hasWritePermission:(NSDictionary *)friend
{
    if (self.allContributors)
        return TRUE;
    
    if (HAVE_ASSERTS)
        assert(self.selectedContributorContacts);
    
    return [self.selectedContributorContacts containsObject:friend];
}

# pragma mark InviteFriendCellDelegate methods
- (void)inviteFriendCellReadButtonTapped:(InviteFriendCell *)cell
{
    NSIndexPath * myIndexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *friend = nil;
    
    if (self.tableView == self.searchDisplayController.searchResultsTableView) {
        friend = [self.filteredListContacts objectAtIndex:myIndexPath.row];
    } else {
        NSArray *contacts = [self getContactsForSection:myIndexPath.section];
        friend = [contacts objectAtIndex:myIndexPath.row];
    }
    
    // Toggle read permission
    if ([self hasReadPermission:friend]) {
        [self.selectedViewerContacts removeObject:friend];
        [cell canRead:NO];
    } else {
        [self.selectedViewerContacts addObject:friend];
        [cell canRead:YES];
    }
}

- (void)inviteFriendCellWriteButtonTapped:(InviteFriendCell *)cell
{
    NSIndexPath * myIndexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *friend = nil;
    
    if (self.tableView == self.searchDisplayController.searchResultsTableView) {
        friend = [self.filteredListContacts objectAtIndex:myIndexPath.row];
    } else {
        NSArray *contacts = [self getContactsForSection:myIndexPath.section];
        friend = [contacts objectAtIndex:myIndexPath.row];
    }
    
    // Toggle write permission
    if ([self hasWritePermission:friend]) {
        [self.selectedContributorContacts removeObject:friend];
        [cell canWrite:NO];
    } else {
        [self.selectedContributorContacts addObject:friend];
        [cell canWrite:YES];
    }
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Don't handle touch events here, let the tableviewcells take care of taps on read/write buttons
    return nil;
}

- (IBAction)doneInviting:(UIBarButtonItem *)sender 
{
    [self.delegate invitedTableViewController:self
                   finishedInvitingForViewers:self.selectedViewerContacts
                                 contributors:self.selectedContributorContacts];
}

- (IBAction)cancel:(UIBarButtonItem *)sender
{
    [self.delegate invitedTableViewControllerDidCancel:self];
}

#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	/*
	 Update the filtered array based on the search text and scope.
	 */
	
	[self.filteredListContacts removeAllObjects]; // First clear the filtered array.
	
    NSPredicate *resultPredicate = [NSPredicate 
                                    predicateWithFormat:@"name beginswith[cd] %@",
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

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
{
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

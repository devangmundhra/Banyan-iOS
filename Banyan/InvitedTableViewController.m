//
//  InvitedTableViewController.m
//  Storied
//
//  Created by Devang Mundhra on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InvitedTableViewController.h"

@interface InvitedTableViewController ()

@property (nonatomic, strong) NSArray *listContacts;
@property (nonatomic, strong) NSMutableArray *filteredListContacts;
@property (strong, nonatomic) NSMutableArray *contactIndex;
@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchDisplayController;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@end

@implementation InvitedTableViewController
@synthesize listContacts = _listContacts;
@synthesize filteredListContacts = _filteredListContacts;
@synthesize objectContext = _objectContext;
@synthesize selectedContacts = _selectedContacts;
@synthesize delegate = _delegate;
@synthesize invitationType = _invitationType;
@synthesize contactIndex = _contactIndex;
@synthesize searchDisplayController;
@synthesize searchBar;

- (id) initWithSearchBarAndNavigationControllerForInvitationType:(NSString *)invitationType
                                                        delegate:(id<InvitedTableViewControllerDelegate>)delegate
                                                selectedContacts:(NSArray *)selectedContacts
{
    if ((self = [super init])) {
        
        /*
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        searchDisplayController.delegate = self;
        searchDisplayController.searchResultsDataSource = self;
         */
        _invitationType = invitationType;
        _delegate = delegate;
        _selectedContacts = [NSMutableArray arrayWithArray:selectedContacts];
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneInviting:)]];
    }
    return self;
}

// When initialized from storyboard
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        /*
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        searchDisplayController.delegate = self;
        searchDisplayController.searchResultsDataSource = self;
         */
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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

- (void)setSelectedContacts:(NSMutableArray *)selectedContacts
{
    if (!_selectedContacts)
        _selectedContacts = [NSMutableArray arrayWithArray:selectedContacts];
}

- (NSMutableArray *)selectedContacts
{
    if (!_selectedContacts)
        _selectedContacts = [NSMutableArray array];
    
    return _selectedContacts;
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

    [[self tableView] setTableHeaderView:searchBar];
    self.searchDisplayController.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tableView.scrollEnabled = YES;
    self.navigationItem.title = self.invitationType;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *array = [defaults objectForKey:BNUserDefaultsFacebookFriends];
    self.listContacts = array;
    [self setContactIndex];
    
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"Invitation view loaded for type %@", self.invitationType]];
}


- (void)viewDidUnload
{
    self.listContacts = nil;
    self.filteredListContacts = nil;
    self.selectedContacts = nil;
    self.delegate = nil;
    self.invitationType = nil;
    self.contactIndex = nil;
    self.searchDisplayController = nil;
    self.searchBar = nil;
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
    static NSString *CellIdentifier = @"ContactCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    // Configure the cell...
    NSDictionary *friend = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        friend = [self.filteredListContacts objectAtIndex:indexPath.row];
        if ([self.selectedContacts containsObject:friend])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        NSArray *contacts = [self getContactsForSection:indexPath.section];
        friend = [contacts objectAtIndex:indexPath.row];
        if ([self.selectedContacts containsObject:friend])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = [friend objectForKey:@"name"];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        if (![self.selectedContacts containsObject:[self.filteredListContacts objectAtIndex:indexPath.row]])
        {
            [self.selectedContacts addObject:[self.filteredListContacts objectAtIndex:indexPath.row]];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
        {
            [self.selectedContacts removeObject:[self.filteredListContacts objectAtIndex:indexPath.row]];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        if (![self.selectedContacts containsObject:[[self getContactsForSection:indexPath.section] objectAtIndex:indexPath.row]])
        {
            [self.selectedContacts addObject:[[self getContactsForSection:indexPath.section] objectAtIndex:indexPath.row]];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
        {
            [self.selectedContacts removeObject:[[self getContactsForSection:indexPath.section] objectAtIndex:indexPath.row]];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

- (IBAction)doneInviting:(UIBarButtonItem *)sender 
{
    [self.delegate invitedTableViewController:self 
                             finishedInviting:self.invitationType
                                 withContacts:[self.selectedContacts copy]];
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

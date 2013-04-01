//
//  LocationPickerTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 12/9/12.
//
//

#import "LocationPickerTableViewController.h"

@interface LocationPickerTableViewController ()
//@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchDisplayController;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@end

@implementation LocationPickerTableViewController
@synthesize locationsFilterResults = _locationsFilterResults;
@synthesize searchBar;
//@synthesize searchDisplayController;
@synthesize locations = _locations;
@synthesize currentLocation = _currentLocation;

- (void) setCurrentLocation:(CLLocation *)currentLocation
{
    _currentLocation = currentLocation;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"Select location";

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self.delegate
                                                                                   action:@selector(locationPickerTableViewControllerDidCancel)];
    [self.navigationItem setLeftBarButtonItem:newBackButton];
    
    // Search bar
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.delegate = self;
    /*the search bar widht must be &gt; 1, the height must be at least 44
     (the real size of the search bar)*/
    
//    self.searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    /*contents controller is the UITableViewController, this let you to reuse
     the same TableViewController Delegate method used for the main table.*/
    
    [self.tableView setContentOffset:CGPointZero animated:NO];
    
//    self.searchDisplayController.delegate = self;
//    self.searchDisplayController.searchResultsDataSource = self;
    
    self.tableView.tableHeaderView = self.searchBar; // this line adds the searchBar
    //on the top of tableView.
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.locationsFilterResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *CellIdentifier = @"LocationCell";
	
	// Dequeue or create a cell of the appropriate type.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell                = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Get the object to display and set the value in the cell.
    //UPDATED from locations to locationFilter results
    GooglePlacesObject *place                       = [self.locationsFilterResults objectAtIndex:[indexPath row]];
    
    cell.textLabel.text                         = place.name;
    cell.textLabel.adjustsFontSizeToFitWidth    = YES;
	cell.textLabel.font                         = [UIFont systemFontOfSize:12.0];
	cell.textLabel.minimumFontSize              = 10;
	cell.textLabel.numberOfLines                = 4;
	cell.textLabel.lineBreakMode                = UILineBreakModeWordWrap;
    cell.textLabel.textColor                    = [UIColor blackColor];
    cell.textLabel.textAlignment                = UITextAlignmentLeft;
    
    //You can use place.distanceInMilesString or place.distanceInFeetString.
    //You can add logic that if distanceInMilesString starts with a 0. then use Feet otherwise use Miles.
    cell.detailTextLabel.text                   = [NSString stringWithFormat:@"%@ - Distance %@ miles", place.vicinity, place.distanceInMilesString];
    cell.detailTextLabel.textColor              = [UIColor darkGrayColor];
    cell.detailTextLabel.font                   = [UIFont systemFontOfSize:10.0];
    
    return cell;
}

- (void)locationManagerDidFinishLoadingWithGooglePlacesObjects:(NSMutableArray *)objects
{
    
    if ([objects count] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No matches found near this location"
                                                        message:@"Try another place name or address"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    } else {
        self.locations = objects;
        //UPDATED locationFilterResults for filtering later on
        self.locationsFilterResults = objects;
        [self.tableView reloadData];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate locationPickerTableViewControllerPickedLocation:[self.locationsFilterResults objectAtIndex:[indexPath row]]];
}

- (void)updateSearchString:(NSString*)aSearchString
{
    [self.delegate getGoogleObjectsWithQuery:aSearchString
                              andCoordinates:CLLocationCoordinate2DMake(self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude)];
    
    [self.tableView reloadData];
}

//Create an array by applying the search string
- (void) buildSearchArrayFrom: (NSString *) matchString
{
	NSString *upString = [matchString uppercaseString];
	
	self.locationsFilterResults = [[NSMutableArray alloc] init];
    
	for (GooglePlacesObject *location in self.locations)
	{
		if ([matchString length] == 0)
		{
			[self.locationsFilterResults addObject:location];
			continue;
		}
		
		NSRange range = [[location.name uppercaseString] rangeOfString:upString];
		
        if (range.location != NSNotFound)
        {
            NSLog(@"Hit");
            
            NSLog(@"Location Name %@", location.name);
            NSLog(@"Search String %@", upString);
            
            [self.locationsFilterResults addObject:location];
        }
	}
	
	[self.tableView reloadData];
}
#pragma mark UISearchDisplayControllerDelegate

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    [theSearchBar setShowsCancelButton:YES animated:YES];
    //Changed to YES to allow selection when in the middle of a search/filter
    self.tableView.allowsSelection   = YES;
    self.tableView.scrollEnabled     = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar
{
    [theSearchBar setShowsCancelButton:NO animated:YES];
    [theSearchBar resignFirstResponder];
    self.tableView.allowsSelection   = YES;
    self.tableView.scrollEnabled     = YES;
    theSearchBar.text           = @"";
    
    [self updateSearchString:searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    self.tableView.allowsSelection   = YES;
    self.tableView.scrollEnabled     = YES;
    
    [self updateSearchString:theSearchBar.text];
}

- (void)searchBar:(UISearchBar *)theSearchBar textDidChange:(NSString *)searchText
{
    [self buildSearchArrayFrom:searchText];
}

@end

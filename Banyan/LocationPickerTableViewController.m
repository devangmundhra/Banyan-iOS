//
//  LocationPickerTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 12/9/12.
//
//

#import "LocationPickerTableViewController.h"

static NSString *CellIdentifier = @"LocationCell";

@interface LocationPickerTableViewController (CLLocationManagerDelegate) <CLLocationManagerDelegate>
- (void) startUpdatingLocation;
- (void) stopUpdatingLocation:(NSString *)state;
@end

@interface LocationPickerTableViewController ()
@property (nonatomic, strong) NSMutableArray    *locationsFilterResults;
@property (nonatomic, strong) NSMutableArray    *locations;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *bestEffortAtLocation;

//@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchDisplayController;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@end

@implementation LocationPickerTableViewController
@synthesize locationsFilterResults = _locationsFilterResults;
@synthesize searchBar;
//@synthesize searchDisplayController;
@synthesize locations = _locations;
@synthesize currentLocation = _currentLocation;
@synthesize locationManager = _locationManager;
@synthesize bestEffortAtLocation = _bestEffortAtLocation;

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
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;//kCLLocationAccuracyBest; // kCLLocationAccuracyNearestTenMeters;
    NSLog(@"%s Initialized shared location manager", __PRETTY_FUNCTION__);
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self
                                                                                   action:@selector(cancelButtonPressed:)];
    [self.navigationItem setLeftBarButtonItem:newBackButton];
    [self.tableView registerClass:[GooglePlacesCell class] forCellReuseIdentifier:CellIdentifier];

    
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
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(startUpdatingLocation) forControlEvents:UIControlEventValueChanged];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Fetching nearby locations"];
    refreshControl.tintColor = BANYAN_GREEN_COLOR;
    self.refreshControl = refreshControl;
    
    [self startUpdatingLocation];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GooglePlacesCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[GooglePlacesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Get the object to display and set the value in the cell.
    //UPDATED from locations to locationFilter results
    NSDictionary *dict                          = [self.locationsFilterResults objectAtIndex:[indexPath row]];
    GooglePlacesObject<GooglePlacesObject>* place = (GooglePlacesObject<GooglePlacesObject>*)[BNDuckTypedObject duckTypedObjectWrappingDictionary:dict];
    [cell setLocation:place andCurrentLocation:self.currentLocation];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSDictionary *dict = [self.locationsFilterResults objectAtIndex:[indexPath row]];
        [self.delegate locationPickerTableViewControllerPickedLocation:(BNDuckTypedObject<GooglePlacesObject>*)([BNDuckTypedObject duckTypedObjectWrappingDictionary:dict])];
    }];
}

- (void)updateSearchString:(NSString*)aSearchString
{
    if (!self.currentLocation) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to find location"
                                                        message:@"There was a problem getting your current location.\rPlease try again later."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    [GooglePlacesObject getGoogleObjectsWithQuery:aSearchString
                                   andCoordinates:CLLocationCoordinate2DMake(self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude)
                                   withCompletion:^(NSArray *places) {
                                       if ([places count] == 0) {
                                           UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No matches found near this location"
                                                                                           message:@"Try another place name or address"
                                                                                          delegate:nil
                                                                                 cancelButtonTitle:@"OK"
                                                                                 otherButtonTitles: nil];
                                           [alert show];
                                       } else {
                                           self.locations = [NSMutableArray arrayWithArray:places];
                                           //UPDATED locationFilterResults for filtering later on
                                           self.locationsFilterResults = [NSMutableArray arrayWithArray:places];
                                           [self.tableView reloadData];
                                       }
                                   }];
}

//Create an array by applying the search string
- (void) buildSearchArrayFrom: (NSString *) matchString
{
	NSString *upString = [matchString uppercaseString];
	
	self.locationsFilterResults = [[NSMutableArray alloc] init];
    
	for (NSMutableDictionary *locationDict in self.locations)
	{
        BNDuckTypedObject<GooglePlacesObject>*location = (BNDuckTypedObject<GooglePlacesObject>*)[BNDuckTypedObject duckTypedObjectWrappingDictionary:locationDict];
        
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

#pragma mark
#pragma target actions
- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation LocationPickerTableViewController (CLLocationManagerDelegate)
- (void) startUpdatingLocation
{
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    [self.refreshControl beginRefreshing];
}

- (void) stopUpdatingLocation:(NSString *)state
{
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    [self.refreshControl endRefreshing];
}

/*
 * We want to get and store a location measurement that meets the desired accuracy. For this example, we are
 *      going to use horizontal accuracy as the deciding factor. In other cases, you may wish to use vertical
 *      accuracy, or both together.
 */
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
    // test the measurement to see if it is more accurate than the previous measurement
    if (self.bestEffortAtLocation == nil || self.bestEffortAtLocation.horizontalAccuracy > newLocation.horizontalAccuracy) {
        // store the location as the "best effort"
        self.bestEffortAtLocation = newLocation;
    }
    // test the measurement to see if it meets the desired accuracy
    // IMPORTANT!!! kCLLocationAccuracyBest should not be used for comparison with location coordinate or altitidue
    // accuracy because it is a negative value. Instead, compare against some predetermined "real" measure of
    // acceptable accuracy, or depend on the timeout to stop updating. This sample depends on a 50m acceptable accuracy
    //
    if (newLocation.horizontalAccuracy <= 50) {
        // IMPORTANT!!! Minimize power usage by stopping the location manager as soon as possible.
        [GooglePlacesObject getNearbyLocations:newLocation withCompletion:^(NSArray *places) {
            if ([places count] == 0) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No matches found near this location"
                                                                message:@"Try another place name or address"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
                [alert show];
            } else {
                self.locations = [NSMutableArray arrayWithArray:places];
                //UPDATED locationFilterResults for filtering later on
                self.locationsFilterResults = [NSMutableArray arrayWithArray:places];
                [self.tableView reloadData];
            }
        }];
        self.currentLocation = newLocation;
        [self stopUpdatingLocation:NSLocalizedString(@"Acquired Location", @"Acquired Location")];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // The location "unknown" error simply means the manager is currently unable to get the location.
    // We can ignore this error for the scenario of getting a single location fix, because we already have a
    // timeout that will stop the location manager to save power.
    if ([error code] != kCLErrorLocationUnknown) {
        switch ([error code]) {
            case kCLErrorDenied:
                [self stopUpdatingLocation:NSLocalizedString(@"Location Services Disabled by User", @"Location Services Disabled by User")];
                break;
            case kCLErrorNetwork:
                [self stopUpdatingLocation:NSLocalizedString(@"Network Unavailable", @"Network Unavailable")];
                break;
            default:
                [self stopUpdatingLocation:NSLocalizedString(@"Error finding location", @"Error finding location")];
                break;
        }
    }
}
@end

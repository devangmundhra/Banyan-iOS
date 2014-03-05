//
//  GooglePlacePickerViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 1/28/14.
//
//

#import "GooglePlacePickerViewController.h"
#import "SPGooglePlacesAutocomplete.h"
#import "BanyanAppDelegate.h"
#import "GooglePlacesCell.h"

static NSString *PlacesDetailCellIdentifier = @"GooglePlacesCell";

@interface GooglePlacePickerViewController ()
@property (nonatomic) BOOL locationObserverAdded;
@end

@implementation GooglePlacePickerViewController
@synthesize searchResultPlaces, searchQuery, selectedPlaceAnnotation, shouldBeginEditing;
@synthesize mapView = _mapView;
@synthesize locationObserverAdded;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        searchQuery = [[SPGooglePlacesAutocompleteQuery alloc] initWithApiKey:GOOGLE_API_KEY];
        shouldBeginEditing = YES;
    }
    return self;
}

- (void)dealloc
{
    if (locationObserverAdded) {
        [self.mapView.userLocation removeObserver:self forKeyPath:@"location"];
        locationObserverAdded = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Select location";
    self.searchDisplayController.searchBar.placeholder = @"Search or Address";
//    self.searchDisplayController.displaysSearchBarInNavigationBar = YES;
    
    [self.mapView.userLocation addObserver:self
                                forKeyPath:@"location"
                                   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
                                   context:NULL];
    locationObserverAdded = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Google Location Picker"];
}

- (IBAction)recenterMapToUserLocation:(id)sender {
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta = 0.02;
    span.longitudeDelta = 0.02;
    
    region.span = span;
    region.center = self.mapView.userLocation.coordinate;
    
    [self.mapView setRegion:region animated:YES];
    
    // Get nearby placemarks for all the establishments
    [GooglePlacesObject getPlacemarkForCLLocation:self.mapView.userLocation.location withCompletion:^(CLPlacemark *placemark, GooglePlacesObject<GooglePlacesObject>* place, NSError *error) {
        if (placemark) {
            GooglePlacesAnnotation *annotation = [[GooglePlacesAnnotation alloc] init];
            annotation.coordinate = placemark.location.coordinate;
            annotation.title = place.name;
            annotation.place = place;
            [self.mapView addAnnotation:annotation];
            [self.mapView selectAnnotation:annotation animated:NO];
        }
    }];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [searchResultPlaces count];
}

- (SPGooglePlacesAutocompletePlace *)placeAtIndexPath:(NSIndexPath *)indexPath {
    return searchResultPlaces[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"SPGooglePlacesAutocompleteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Roboto" size:12.0];
    cell.textLabel.text = [self placeAtIndexPath:indexPath].name;
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)recenterMapToPlacemark:(CLPlacemark *)placemark {
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta = 0.2;
    span.longitudeDelta = 0.2;
    
    region.span = span;
    region.center = placemark.location.coordinate;
    
    [self.mapView setRegion:region];
}

- (void)addPlacemarkAnnotationToMap:(CLPlacemark *)placemark place:(GooglePlacesObject<GooglePlacesObject>*)place{
    [self.mapView removeAnnotation:selectedPlaceAnnotation];
    
    selectedPlaceAnnotation = [[GooglePlacesAnnotation alloc] init];
    selectedPlaceAnnotation.coordinate = placemark.location.coordinate;
    selectedPlaceAnnotation.title = place.name;
    selectedPlaceAnnotation.place = place;
    [self.mapView addAnnotation:selectedPlaceAnnotation];
}

- (void)dismissSearchController {
    // Animate out the table view.
    NSTimeInterval animationDuration = 0.3;
    [UIView animateWithDuration:animationDuration animations:^{
        self.searchDisplayController.searchResultsTableView.alpha = 0.0;

    } completion:^(BOOL finished) {
        [self.searchDisplayController setActive:NO];

    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SPGooglePlacesAutocompletePlace *place = [self placeAtIndexPath:indexPath];
    [place resolveToPlacemark:^(CLPlacemark *placemark, NSString *addressString, NSError *error) {
        if (error || !placemark) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not map selected place"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        } else {
            GooglePlacesObject<GooglePlacesObject>* gpoPlace = (GooglePlacesObject<GooglePlacesObject>*)[GooglePlacesObject duckTypedObject];
            gpoPlace.name = addressString;
            gpoPlace.geometry.location.lat = [NSNumber numberWithDouble:placemark.location.coordinate.latitude];
            gpoPlace.geometry.location.lng = [NSNumber numberWithDouble:placemark.location.coordinate.longitude];
            
            [self addPlacemarkAnnotationToMap:placemark place:gpoPlace];
            [self recenterMapToPlacemark:placemark];
            [self dismissSearchController];
            [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }];
}

#pragma mark -
#pragma mark UISearchDisplayDelegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    // The user has chosen to search for the location. Cancel the KVO that centers on user location
    if (locationObserverAdded) {
        [self.mapView.userLocation removeObserver:self forKeyPath:@"location"];
        locationObserverAdded = NO;
    }
}

- (void)handleSearchForSearchString:(NSString *)searchString {
    searchQuery.location = self.mapView.userLocation.coordinate;
    searchQuery.input = searchString;
    [searchQuery fetchPlaces:^(NSArray *places, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not fetch Places"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        } else {
            searchResultPlaces = places;
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
    }];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self handleSearchForSearchString:searchString];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

#pragma mark -
#pragma mark UISearchBar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (![searchBar isFirstResponder]) {
        // User tapped the 'clear' button.
        shouldBeginEditing = NO;
        [self.searchDisplayController setActive:NO];
        [self.mapView removeAnnotation:selectedPlaceAnnotation];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    if (shouldBeginEditing) {
        // Animate in the table view.
        NSTimeInterval animationDuration = 0.3;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        self.searchDisplayController.searchResultsTableView.alpha = 0.75;
        [UIView commitAnimations];
        
        [self.searchDisplayController.searchBar setShowsCancelButton:YES animated:YES];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"powered-by-google-on-white"]];
        imageView.contentMode = UIViewContentModeRight;
        self.searchDisplayController.searchResultsTableView.tableFooterView = imageView;
    }
    BOOL boolToReturn = shouldBeginEditing;
    shouldBeginEditing = YES;
    return boolToReturn;
}

#pragma mark -
#pragma mark MKMapView Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapViewIn viewForAnnotation:(id <MKAnnotation>)annotation {
    if (mapViewIn != self.mapView || [annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    static NSString *annotationIdentifier = @"SPGooglePlacesAutocompleteAnnotation";
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    if (!annotationView) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
    }
    annotationView.animatesDrop = YES;
    annotationView.canShowCallout = YES;
    
    UIButton *detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    annotationView.rightCalloutAccessoryView = detailButton;
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    // Whenever we've dropped a pin on the map, immediately select it to present its callout bubble.
    [self.mapView selectAnnotation:selectedPlaceAnnotation animated:YES];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    GooglePlacesAnnotation *annotation = view.annotation;
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate googlePlacesViewControllerPickedLocation:annotation.place];
    }];
}

#pragma mark
#pragma target actions
- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark
#pragma KVO
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([self.mapView isUserLocationVisible]) {
        [self recenterMapToUserLocation:nil];
        if (locationObserverAdded) {
            [self.mapView.userLocation removeObserver:self forKeyPath:@"location"];
            locationObserverAdded = NO;
        }
    }
}

@end

//
//  GooglePlacePickerViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 1/28/14.
//
//

#import "GooglePlacePickerViewController.h"
#import "BanyanAppDelegate.h"
#import "GooglePlacesCell.h"
#import "AFGooglePlacesAPIClient.h"
#import "GooglePlacePickerTableViewCell.h"

// Note that the searchBar in the nib file has width zero.
// This is by design because otherwise during the view did appear animation, the
// search bar first animates to the middle of the view, and then slides to the top,
// which makes the view appearance a bit awkward.
const int cameraZoom = 15;

@interface GooglePlacePickerViewController (GooglePlacePickerTableViewCellDelegate) <GooglePlacePickerTableViewCellDelegate>
@end

@interface GooglePlacePickerViewController (GMSMapViewDelegate) <GMSMapViewDelegate>
@end

static NSString *PlacesDetailCellIdentifier = @"GooglePlacesCell";

@interface GooglePlacePickerViewController () <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *nearbyTableView;

@property (strong, nonatomic) NSArray *nearbyPlaces;
@property (strong ,nonatomic) NSArray *tableViewPlaces;

@property (strong, nonatomic) NSArray *searchResultPlaces;

@property (nonatomic) BOOL locationObserverAdded;
@property (nonatomic) BOOL shouldBeginEditing;
@property (nonatomic) BOOL firstLocationUpdate;

@end

static const NSArray *markerColors = nil;

@implementation GooglePlacePickerViewController
@synthesize tableViewPlaces;
@synthesize nearbyPlaces;
@synthesize searchResultPlaces, shouldBeginEditing;
@synthesize mapView = _mapView;
@synthesize locationObserverAdded;
@synthesize firstLocationUpdate;

+ (void)initialize
{
    markerColors = @[BANYAN_BROWN_COLOR,
                    BANYAN_DARK_GREEN_COLOR,
                    BANYAN_RED_COLOR,
                    BANYAN_LIGHT_GREEN_COLOR,
                    BANYAN_PINK_COLOR,
                    BANYAN_DARKBROWN_COLOR];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shouldBeginEditing = YES;
    }
    return self;
}

- (void)dealloc
{
    if (locationObserverAdded) {
        [self.mapView removeObserver:self forKeyPath:@"myLocation"];
        locationObserverAdded = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Select location";
    self.searchDisplayController.displaysSearchBarInNavigationBar = YES;
    self.searchDisplayController.searchBar.placeholder = @"Search a Place";
    GMSCameraPosition *camera = nil;
    if ([self.delegate currentLocation]) {
        camera = [GMSCameraPosition cameraWithTarget:[self.delegate currentLocation].coordinate
                                                zoom:cameraZoom];
    } else {
        camera = [GMSCameraPosition cameraWithLatitude:37.78
                                             longitude:122.41
                                                  zoom:kGMSMinZoomLevel];
    }

    
    self.mapView.camera = camera;
    self.mapView.settings.compassButton = YES;
    self.mapView.settings.myLocationButton = YES;
    self.mapView.delegate = self;

    // Setup location services
    if (   [CLLocationManager locationServicesEnabled]
        && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {
        // Listen to the myLocation property of GMSMapView.
        [self.mapView addObserver:self
                       forKeyPath:@"myLocation"
                          options:NSKeyValueObservingOptionNew
                          context:NULL];
        
        locationObserverAdded = YES;
        
        // Ask for My Location data after the map has already been added to the UI.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.mapView.myLocationEnabled = YES;
        });
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Google Location Picker"];
}

-(IBAction)goBack:(id)sender {
	// Some anything you need to do before leaving
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchDisplayController.isActive) {
        return [searchResultPlaces count];
    } else {
        return [tableViewPlaces count];
    }
}

- (id)placeAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchDisplayController.isActive) {
        return searchResultPlaces[indexPath.row];
    } else {
        return tableViewPlaces[indexPath.row];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"GooglePlaces";
    GooglePlacePickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[GooglePlacePickerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.delegate = self;
    UIColor *color = nil;
    
    id place = [self placeAtIndexPath:indexPath];
    NSString *name = nil;
    if (self.searchDisplayController.isActive) {
        name = ((GooglePlacesAutocompletePlace *)place).name;
        [cell setWithName:name place:place color:color markOnMap:NO];
    } else {
        name = ((GooglePlacesObject<GooglePlacesObject> *)place).name;
        if ([tableViewPlaces count] > 1)
            // There is just one place, no need to color it specially
            color = [markerColors objectAtIndex:(indexPath.row % markerColors.count)];
        [cell setWithName:name place:place color:color markOnMap:YES];
    }

    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)recenterMapToLocation:(CLLocation *)location
{
    if (!location || !CLLocationCoordinate2DIsValid(location.coordinate)) {
        return;
    }
    
    const float animationDuration = 2.0f;
    
    self.mapView.layer.cameraLatitude = location.coordinate.latitude;
    self.mapView.layer.cameraLongitude = location.coordinate.longitude;
    self.mapView.layer.cameraBearing = 0.0;
    
    // Access the GMSMapLayer directly to modify the following properties with a
    // specified timing function and duration.
    
    CAMediaTimingFunction *curve =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    CABasicAnimation *animation;
    
    animation = [CABasicAnimation animationWithKeyPath:kGMSLayerCameraLatitudeKey];
    animation.duration = animationDuration;
    animation.timingFunction = curve;
    animation.toValue = @(location.coordinate.latitude);
    [self.mapView.layer addAnimation:animation forKey:kGMSLayerCameraLatitudeKey];
    
    animation = [CABasicAnimation animationWithKeyPath:kGMSLayerCameraLongitudeKey];
    animation.duration = animationDuration;
    animation.timingFunction = curve;
    animation.toValue = @(location.coordinate.longitude);
    [self.mapView.layer addAnimation:animation forKey:kGMSLayerCameraLongitudeKey];
    
    animation = [CABasicAnimation animationWithKeyPath:kGMSLayerCameraBearingKey];
    animation.duration = animationDuration;
    animation.timingFunction = curve;
    animation.toValue = @0.0;
    [self.mapView.layer addAnimation:animation forKey:kGMSLayerCameraBearingKey];
    
//    // Fly out to the minimum zoom and then zoom back to the current zoom!
//    CGFloat zoom = self.mapView.camera.zoom;
//    NSArray *keyValues = @[@(zoom), @(kGMSMinZoomLevel), @(zoom)];
//    CAKeyframeAnimation *keyFrameAnimation =
//    [CAKeyframeAnimation animationWithKeyPath:kGMSLayerCameraZoomLevelKey];
//    keyFrameAnimation.duration = animationDuration;
//    keyFrameAnimation.values = keyValues;
//    [self.mapView.layer addAnimation:keyFrameAnimation forKey:kGMSLayerCameraZoomLevelKey];
}

- (void)dismissSearchControllerWithCompletion:(void (^)(void))completionBlock {
    // Animate out the table view.
    NSTimeInterval animationDuration = 0.3;
    [UIView animateWithDuration:animationDuration animations:^{
        self.searchDisplayController.searchResultsTableView.alpha = 0.0;

    } completion:^(BOOL finished) {
        [self.searchDisplayController setActive:NO];
        if (completionBlock) completionBlock();
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchDisplayController.isActive) {
        GooglePlacesAutocompletePlace *place = [self placeAtIndexPath:indexPath];
        [[AFGooglePlacesAPIClient sharedClient] getPlaceDetailsWitReference:place.reference
                                                             withCompletion:^(NSDictionary *placeDictionary, NSError *error) {
                                                                 if (error || !placeDictionary) {
                                                                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not map selected place"
                                                                                                                     message:error.localizedDescription
                                                                                                                    delegate:nil
                                                                                                           cancelButtonTitle:@"OK"
                                                                                                           otherButtonTitles:nil, nil];
                                                                     [alert show];
                                                                 } else {
                                                                     GooglePlacesObject<GooglePlacesObject>* gpoPlace = (GooglePlacesObject<GooglePlacesObject>*)[GooglePlacesObject duckTypedObjectWrappingDictionary:placeDictionary];

                                                                     [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:NO];
                                                                     [self dismissSearchControllerWithCompletion:^{
                                                                         [self recenterMapToLocation:[[CLLocation alloc] initWithLatitude:[gpoPlace.geometry.location.lat doubleValue] longitude:[gpoPlace.geometry.location.lng doubleValue]]];
                                                                         tableViewPlaces = @[gpoPlace];
                                                                         [self.mapView clear];
                                                                         [self.nearbyTableView reloadData];
                                                                     }];
                                                                 }
                                                             }];
    } else {
        [self.delegate googlePlacesViewControllerPickedLocation:[self placeAtIndexPath:indexPath]];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark UISearchDisplayDelegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    // The user has chosen to search for the location. Cancel the KVO that centers on user location
    if (locationObserverAdded) {
        [self.mapView removeObserver:self forKeyPath:@"myLocation"];
        locationObserverAdded = NO;
    }
    [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"user searching for location" label:nil value:nil];
}

- (void)handleSearchForSearchString:(NSString *)searchString {
//    searchQuery.location = self.mapView.userLocation.coordinate;
    [[AFGooglePlacesAPIClient sharedClient] autoCompletePlacesForQuery:searchString
                                                          nearLocation:nil
                                                        withCompletion:^(NSArray *places, NSError *error) {
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
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"powered-by-google-on-white"]];
        imageView.contentMode = UIViewContentModeRight;
        self.searchDisplayController.searchResultsTableView.tableFooterView = imageView;
    }
    BOOL boolToReturn = shouldBeginEditing;
    shouldBeginEditing = YES;
    return boolToReturn;
}

#pragma mark
#pragma KVO
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if (!firstLocationUpdate) {
        firstLocationUpdate = YES;
        CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
        self.mapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate
                                                             zoom:cameraZoom];
        [self getNearbyPlacesAndRefreshTable];

    }
}

// Fetch nearby places
- (void) getNearbyPlacesAndRefreshTable
{
    // Get nearby location
    [[AFGooglePlacesAPIClient sharedClient] getNearbyLocations:self.mapView.myLocation withCompletion:^(NSArray *places, NSError *error) {
        if (!error) {
            nearbyPlaces = places;
            tableViewPlaces = nearbyPlaces;
            [self.mapView clear];
            [self.nearbyTableView reloadData];
        }
    }];
}
@end

@implementation GooglePlacePickerViewController (GMSMapViewDelegate)

/**
 * Called when the My Location button is tapped.
 *
 * @return YES if the listener has consumed the event (i.e., the default behavior should not occur),
 *         NO otherwise (i.e., the default behavior should occur). The default behavior is for the
 *         camera to move such that it is centered on the user location.
 */
- (BOOL)didTapMyLocationButtonForMapView:(GMSMapView *)mapView
{
    [self.mapView clear];
    
    // Fetch nearby places
    if (nearbyPlaces) {
        tableViewPlaces = nearbyPlaces;
        [self.mapView clear];
        [self.nearbyTableView reloadData];
    }
    else
        [self getNearbyPlacesAndRefreshTable];
    return NO;
}

@end

@implementation GooglePlacePickerViewController (GooglePlacePickerTableViewCellDelegate)
- (GMSMarker *)addMarkerAtPlace:(GooglePlacesObject<GooglePlacesObject>*)place withColor:(UIColor *)color
{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake([place.geometry.location.lat doubleValue], [place.geometry.location.lng doubleValue]);
    marker.appearAnimation = kGMSMarkerAnimationPop;
    marker.title = place.name;
    if (color)
        marker.icon = [GMSMarker markerImageWithColor:color];
    marker.map = self.mapView;
    return marker;
}
@end
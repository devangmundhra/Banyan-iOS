//
//  BNFBLocationManager.m
//  Banyan
//
//  Created by Devang Mundhra on 4/15/13.
//
//

#import "BNFBLocationManager.h"

@interface BNFBLocationManager ()

@property (strong, nonatomic) CLLocation *bestEffortAtLocation;

@end

@implementation BNFBLocationManager

static CLLocationManager *_sharedLocationManager;

@synthesize location = _location;
@synthesize delegate = _delegate;
@synthesize locationStatus = _locationStatus;
@synthesize bestEffortAtLocation = _bestEffortAtLocation;
@synthesize placePickerViewController = _placePickerViewController;

- (void)setLocation:(NSDictionary<FBGraphPlace> *)location
{
    _location = location;
    // Also let the delegate know that we have a new string so that it can use it
    [self.delegate locationUpdated];
}

- (BNPlacePickerViewController *)placePickerViewController
{
    if (!_placePickerViewController) {
        _placePickerViewController = [[BNPlacePickerViewController alloc] initWithNibName:nil bundle:nil];
        _placePickerViewController.delegate = self;
    }
    return _placePickerViewController;
}

- (id)initWithDelegate:(id<BNFBLocationManagerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _location = nil;
        _delegate = delegate;
        _locationStatus = FINDING_LOCATION_STRING;
    }
    return self;
}

# pragma mark class methods
+ (void ) initialize
{
    if (!_sharedLocationManager) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedLocationManager = [[CLLocationManager alloc] init];
            _sharedLocationManager.desiredAccuracy = kCLLocationAccuracyBest; // kCLLocationAccuracyNearestTenMeters;
            NSLog(@"%s Initialized shared location manager", __PRETTY_FUNCTION__);
        });
    }
}

+ (void) dealloc
{
    NSLog(@"%s Dealloc'ed shared location manager", __PRETTY_FUNCTION__);
    [_sharedLocationManager stopUpdatingLocation];
    _sharedLocationManager.delegate = nil;
    _sharedLocationManager = nil;
}

# pragma mark CLLocationManagerDelegate
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
        
        // test the measurement to see if it meets the desired accuracy
        // IMPORTANT!!! kCLLocationAccuracyBest should not be used for comparison with location coordinate or altitidue
        // accuracy because it is a negative value. Instead, compare against some predetermined "real" measure of
        // acceptable accuracy, or depend on the timeout to stop updating. This sample depends on a 5m acceptable accuracy
        //
        if (newLocation.horizontalAccuracy <= 10) {
            // IMPORTANT!!! Minimize power usage by stopping the location manager as soon as possible.
            [self getNearbyLocations:newLocation];
            self.placePickerViewController.locationCoordinate = newLocation.coordinate;
            [self stopUpdatingLocation:nil];
        }
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


# pragma mark BNLocationManager
- (void)beginUpdatingLocation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopUpdatingLocation:) object:nil];
    _sharedLocationManager.delegate = self;
    [_sharedLocationManager startUpdatingLocation];
    
}

- (void)stopUpdatingLocation:(NSString *)state
{
    if (state) {
        self.locationStatus = state;
    }
    [_sharedLocationManager stopUpdatingLocation];
    _sharedLocationManager.delegate = nil;
}

- (void) getNearbyLocations:(CLLocation *)location
{
    [FBRequestConnection startForPlacesSearchAtCoordinate:location.coordinate radiusInMeters:50000 resultsLimit:1 searchText:nil completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSLog(@"result: %@", result);
        
        NSArray *data = [result objectForKey:@"data"];
        
        if (data && [data count]) {
            // We have the places data
            self.location = [data objectAtIndex:0];
        }
    }];
}

- (void) showPlacePickerViewController
{
    [self beginUpdatingLocation];
    
    if ([self.delegate isKindOfClass:[UIViewController class]]) {
        [(UIViewController *)self.delegate presentViewController:self.placePickerViewController animated:YES completion:^{
            [self.placePickerViewController loadData];
        }];
    }
}

#pragma mark FBPlacePickerDelegate
- (void)placePickerViewController:(FBPlacePickerViewController *)placePicker handleError:(NSError *)error
{
    self.location = nil;
    self.locationStatus = [error localizedDescription];
}

- (BOOL)placePickerViewController:(FBPlacePickerViewController *)placePicker shouldIncludePlace:(id <FBGraphPlace>)place
{
    return YES;
}

- (void)placePickerViewControllerDataDidChange:(FBPlacePickerViewController *)placePicker
{

}

- (void)placePickerViewControllerSelectionDidChange:(FBPlacePickerViewController *)placePicker
{
    self.location = (NSDictionary<FBGraphPlace> *)placePicker.selection;
    self.locationStatus = self.location.name;
    [self stopUpdatingLocation:self.locationStatus];
    if ([self.delegate isKindOfClass:[UIViewController class]]) {
        [(UIViewController *)self.delegate dismissViewControllerAnimated:YES completion:nil];
    }
}

@end

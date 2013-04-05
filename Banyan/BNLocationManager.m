//
//  BNLocationManager.m
//  Banyan
//
//  Created by Devang Mundhra on 8/7/12.
//
//

#import "BNLocationManager.h"
#import "AFGoogleAPIClient.h"
#import "BanyanAppDelegate.h"

@interface BNLocationManager ()
@property (strong, nonatomic) CLLocation *bestEffortAtLocation;
@property (strong, nonatomic) NSArray *locationsNearThisLocation;
@end

@implementation BNLocationManager

static CLLocationManager *_sharedLocationManager;

@synthesize location = _location;
@synthesize delegate = _delegate;
@synthesize locationStatus = _locationStatus;
@synthesize bestEffortAtLocation = _bestEffortAtLocation;
@synthesize locationPickerViewController = _locationPickerViewController;
@synthesize locationsNearThisLocation = _locationsNearThisLocation;

- (void)setLocation:(GooglePlacesObject *)location
{
    _location = location;
    // Also let the delegate know that we have a new string so that it can use it
    [self.delegate locationUpdated];
}

- (void)setLocationsNearThisLocation:(NSArray *)locationsNearThisLocation
{
    _locationsNearThisLocation = locationsNearThisLocation;
    self.location = [locationsNearThisLocation objectAtIndex:0];
    self.locationStatus = [self.location getFormattedName];
}

- (LocationPickerTableViewController *)locationPickerViewController
{
    if (!_locationPickerViewController) {
        _locationPickerViewController = [[LocationPickerTableViewController alloc] initWithStyle:UITableViewStylePlain];
        _locationPickerViewController.delegate = self;
    }
    return _locationPickerViewController;
}

- (id)initWithDelegate:(id<BNLocationManagerDelegate>)delegate
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
            self.locationPickerViewController.currentLocation = newLocation;
            [self stopUpdatingLocation:self.locationStatus];
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
    [self.delegate locationUpdated];
    _sharedLocationManager.delegate = self;
    [_sharedLocationManager startUpdatingLocation];
    
}

- (void)stopUpdatingLocation:(NSString *)state
{
    self.locationStatus = state;
    [_sharedLocationManager stopUpdatingLocation];
    _sharedLocationManager.delegate = nil;
}

- (void) getNearbyLocations:(CLLocation *)location
{
    NSString *coords = [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
    NSString *types =[NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@",
                      kBar,
                      kRestaurant,
                      kCafe,
                      kBakery,
                      kFood,
                      kLodging,
                      kMealDelivery,
                      kMealTakeaway,
                      kNightClub,
                      kEstablishment,
                      kGeocode,
                      kLodging,
                      kUniversity];
                       
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:GOOGLE_API_KEY forKey:@"key"];
    [parameters setObject:coords forKey:@"location"];
    [parameters setObject:types forKey:@"types"];
    [parameters setObject:@"distance" forKey:@"rankby"];
    [parameters setObject:@"true" forKey:@"sensor"];
    
    [[AFGoogleAPIClient sharedClient] getPath:GOOGLE_API_NEARBY_PLACES_URL()
                                   parameters:parameters
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *results = (NSDictionary *)responseObject;
                                          if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_ERROR_STATUS]) {
                                              if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_NO_RESULTS_STATUS]) {
                                                  NSDictionary *gResponseData  = [results objectForKey: @"results"];
                                                  NSMutableArray *googlePlacesObjects = [NSMutableArray arrayWithCapacity:[[results objectForKey:@"results"] count]];
                                                  
                                                  for (NSDictionary *result in gResponseData)
                                                  {
                                                      [googlePlacesObjects addObject:result];
                                                  }
                                                  
                                                  for (int x=0; x<[googlePlacesObjects count]; x++)
                                                  {
                                                      GooglePlacesObject *object = [[GooglePlacesObject alloc] initWithJsonResultDict:[googlePlacesObjects objectAtIndex:x] andUserCoordinates:location.coordinate];
                                                      [googlePlacesObjects replaceObjectAtIndex:x withObject:object];
                                                  }
                                                  [self.locationPickerViewController locationManagerDidFinishLoadingWithGooglePlacesObjects:googlePlacesObjects];
                                                  self.locationsNearThisLocation = [googlePlacesObjects copy];
                                              }
                                          } else {
                                              [TestFlight passCheckpoint:[NSString stringWithFormat:@"Invalid Google Maps API request %@", operation]];
                                          }
                                      }
                                      failure:AF_GOOGLE_ERROR_BLOCK()];
    
    return;
}

-(void)getGoogleObjectsWithQuery:(NSString *)query
                  andCoordinates:(CLLocationCoordinate2D)coords
{
    assert(coords.latitude!=0 && coords.longitude!=0);
    NSString *coordsString = [NSString stringWithFormat:@"%f,%f", coords.latitude, coords.longitude];
    NSString *types =[NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@",
                      kBar,
                      kRestaurant,
                      kCafe,
                      kBakery,
                      kFood,
                      kLodging,
                      kMealDelivery,
                      kMealTakeaway,
                      kNightClub,
                      kEstablishment,
                      kGeocode,
                      kLodging,
                      kUniversity];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:GOOGLE_API_KEY forKey:@"key"];
    [parameters setObject:coordsString forKey:@"location"];
    [parameters setObject:types forKey:@"types"];
    [parameters setObject:@"1000" forKey:@"radius"];
    [parameters setObject:@"true" forKey:@"sensor"];
    [parameters setObject:query forKey:@"name"];
    
    [[AFGoogleAPIClient sharedClient] getPath:GOOGLE_API_SEARCH_PLACES_URL()
                                   parameters:parameters
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *results = (NSDictionary *)responseObject;
                                          if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_ERROR_STATUS]) {
                                              if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_NO_RESULTS_STATUS]) {
                                                  NSDictionary *gResponseData  = [results objectForKey: @"results"];
                                                  NSMutableArray *googlePlacesObjects = [NSMutableArray arrayWithCapacity:[[results objectForKey:@"results"] count]];
                                                  
                                                  for (NSDictionary *result in gResponseData)
                                                  {
                                                      [googlePlacesObjects addObject:result];
                                                  }
                                                  
                                                  for (int x=0; x<[googlePlacesObjects count]; x++)
                                                  {
                                                      GooglePlacesObject *object = [[GooglePlacesObject alloc] initWithJsonResultDict:[googlePlacesObjects objectAtIndex:x] andUserCoordinates:coords];
                                                      [googlePlacesObjects replaceObjectAtIndex:x withObject:object];
                                                  }
                                                  [self.locationPickerViewController locationManagerDidFinishLoadingWithGooglePlacesObjects:googlePlacesObjects];
                                              }
                                          } else {
                                              [TestFlight passCheckpoint:[NSString stringWithFormat:@"Invalid Google Maps API request %@", operation]];
                                          }
                                      }
                                      failure:AF_GOOGLE_ERROR_BLOCK()];
}

- (void) showLocationPickerTableViewController
{
    [self beginUpdatingLocation];
    
    if ([self.delegate isKindOfClass:[UIViewController class]]) {
        // Create the navigation controller and present it.
        UINavigationController *navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:self.locationPickerViewController];
        [(UIViewController *)self.delegate presentViewController:navigationController animated:YES completion:nil];
    }
}

#pragma mark LocationPickerTableViewControllerDelegate
- (void)locationPickerTableViewControllerDidCancel
{
    if ([self.delegate isKindOfClass:[UIViewController class]]) {
        [(UIViewController *)self.delegate dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)locationPickerTableViewControllerPickedLocation:(GooglePlacesObject *)place
{
    self.location = place;
    self.locationStatus = [self.location getFormattedName];
    [self stopUpdatingLocation:self.locationStatus];
    if ([self.delegate isKindOfClass:[UIViewController class]]) {
        [(UIViewController *)self.delegate dismissViewControllerAnimated:YES completion:nil];
    }
}

@end

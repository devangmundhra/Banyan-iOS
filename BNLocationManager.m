//
//  BNLocationManager.m
//  Banyan
//
//  Created by Devang Mundhra on 8/7/12.
//
//

#import "BNLocationManager.h"

@implementation BNLocationManager

static CLLocationManager *_sharedLocationManager;

@synthesize location = _location;
@synthesize locationString = _locationString;
@synthesize delegate = _delegate;
@synthesize locationStatus = _locationStatus;

- (void)setLocationStatus:(NSString *)locationStatus
{
    _locationStatus = locationStatus;
    // Also let the delegate know that we have a new string so that it can use it
    [self.delegate locationUpdated];
}

+ (void ) initialize
{
    if (!_sharedLocationManager) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedLocationManager = [[CLLocationManager alloc] init];
            _sharedLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
            NSLog(@"%s Initialized shared location manager", __PRETTY_FUNCTION__);
        });
    }
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
    if (self.location == nil || self.location.horizontalAccuracy > newLocation.horizontalAccuracy) {
        // store the location as the "best effort"
        self.location = newLocation;
        
        [self reverseGeoCodedLocation:self.location];
        
        // test the measurement to see if it meets the desired accuracy
        if (newLocation.horizontalAccuracy <= _sharedLocationManager.desiredAccuracy) {
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
- (void) reverseGeoCodedLocation:(CLLocation *)location
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%s Error in geocoding location data. Error %@", __PRETTY_FUNCTION__, error);
        } else {
            if (placemarks && placemarks.count > 0) {
                //do something
                CLPlacemark *topResult = [placemarks objectAtIndex:0];
                NSString *addressTxt = [NSString stringWithFormat:@"%@, %@ %@",
                                        [topResult thoroughfare],
                                        [topResult locality], [topResult administrativeArea]];
                NSLog(@"%@",addressTxt);
                self.locationString = addressTxt;
                self.locationStatus = self.locationString;
                [TestFlight passCheckpoint:@"Got Location"];
            }
        }
    }];
}

- (void)beginUpdatingLocation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopUpdatingLocation:) object:nil];
    _sharedLocationManager.delegate = self;
    self.location = nil;
    self.locationString = nil;
    self.locationStatus = @"Finding location...";
    [_sharedLocationManager startUpdatingLocation];

}

- (void)stopUpdatingLocation:(NSString *)state
{
    self.locationStatus = state;
    [_sharedLocationManager stopUpdatingLocation];
    _sharedLocationManager.delegate = nil;
}

@end

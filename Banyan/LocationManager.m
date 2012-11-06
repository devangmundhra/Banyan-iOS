//
//  LocationManager.m
//  Banyan
//
//  Created by Devang Mundhra on 8/7/12.
//
//

#import "LocationManager.h"

@interface LocationManager()

@end

@implementation LocationManager

static CLLocationManager *_sharedLocationManager;

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
        
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:self.location completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error) {
                NSLog(@"%s Error in geocoding location data. Error %@", __PRETTY_FUNCTION__, error);
                [self beginUpdatingLocation];
            } else {
                if(placemarks && placemarks.count > 0)
                {
                    //do something
                    CLPlacemark *topResult = [placemarks objectAtIndex:0];
                    NSString *addressTxt = [NSString stringWithFormat:@"at %@, %@ %@",
                                            [topResult thoroughfare],
                                            [topResult locality], [topResult administrativeArea]];
                    NSLog(@"%@",addressTxt);
                    self.locationLabel.text = addressTxt;
                    
                    [TestFlight passCheckpoint:@"Got story location"];
                }
            }
        }];
        
        // test the measurement to see if it meets the desired accuracy
        if (newLocation.horizontalAccuracy <= self.locationManager.desiredAccuracy) {
            self.isLocationSet = YES;
            [self stopUpdatingLocation:self.locationLabel.text];
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

# pragma mark location settings
- (IBAction)showLocationSwitchToggled:(UISwitch *)sender
{
    if (self.showLocationSwitch.on) {
        [self beginUpdatingLocation];
    } else {
        [self stopUpdatingLocation:nil];
        self.isLocationSet = NO;
        self.location = nil;
    }
}

- (void)beginUpdatingLocation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopUpdatingLocation:) object:nil];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [self.locationManager startUpdatingLocation];
    if (!self.locationLabel.text) {
        self.locationLabel.text = @"Finding location...";
    }
}

- (void)stopUpdatingLocation:(NSString *)state
{
    self.locationLabel.text = state;
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
}

@end

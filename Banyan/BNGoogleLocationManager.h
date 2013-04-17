//
//  BNGoogleLocationManager.h
//  Banyan
//
//  Created by Devang Mundhra on 8/7/12.
//
//

#import <Foundation/Foundation.h>
#import "GooglePlacesObject.h"
#import "LocationPickerTableViewController.h"

#define FINDING_LOCATION_STRING @"Finding location..."

@protocol BNGoogleLocationManagerDelegate <NSObject>

- (void)locationUpdated;

@end

@interface BNGoogleLocationManager : NSObject <CLLocationManagerDelegate, LocationPickerTableViewControllerDelegate>

@property (nonatomic, strong) GooglePlacesObject *location;
@property (nonatomic, strong) NSString *locationStatus;
@property (nonatomic, weak) id <BNGoogleLocationManagerDelegate> delegate;
@property (nonatomic, strong) LocationPickerTableViewController *locationPickerViewController;

- (id)initWithDelegate:(id<BNGoogleLocationManagerDelegate>)delegate;
- (void) beginUpdatingLocation;
- (void) stopUpdatingLocation:(NSString *)state;
- (void) getNearbyLocations:(CLLocation *)location;
- (void) showLocationPickerTableViewController;

@end

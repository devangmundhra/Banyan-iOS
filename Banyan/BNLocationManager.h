//
//  BNLocationManager.h
//  Banyan
//
//  Created by Devang Mundhra on 8/7/12.
//
//

#import <Foundation/Foundation.h>
#import "GooglePlacesObject.h"
#import "LocationPickerTableViewController.h"

#define FINDING_LOCATION_STRING @"Finding location..."

@protocol BNLocationManagerDelegate <NSObject>

- (void)locationUpdated;

@end

@interface BNLocationManager : NSObject <CLLocationManagerDelegate, LocationPickerTableViewControllerDelegate>

@property (nonatomic, strong) GooglePlacesObject *location;
@property (nonatomic, strong) NSString *locationStatus;
@property (nonatomic, weak) id <BNLocationManagerDelegate> delegate;
@property (nonatomic, strong) LocationPickerTableViewController *locationPickerViewController;

- (id)initWithDelegate:(id<BNLocationManagerDelegate>)delegate;
- (void) beginUpdatingLocation;
- (void) stopUpdatingLocation:(NSString *)state;
- (void) getNearbyLocations:(CLLocation *)location;

@end

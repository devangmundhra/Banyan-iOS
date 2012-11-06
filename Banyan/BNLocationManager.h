//
//  BNLocationManager.h
//  Banyan
//
//  Created by Devang Mundhra on 8/7/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define FINDING_LOCATION_STRING @"Finding location..."

@protocol BNLocationManagerDelegate <NSObject>

- (void)locationUpdated;

@end

@interface BNLocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) NSString *locationString;
@property (nonatomic, strong) NSString *locationStatus;
@property (nonatomic, weak) id <BNLocationManagerDelegate> delegate;

- (void) beginUpdatingLocation;
- (void) stopUpdatingLocation:(NSString *)state;
- (void) reverseGeoCodedLocation:(CLLocation *)location;

@end

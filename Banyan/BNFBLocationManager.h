//
//  BNFBLocationManager.h
//  Banyan
//
//  Created by Devang Mundhra on 4/15/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BNPlacePickerViewController.h"
#import "Location.h"

#define FINDING_LOCATION_STRING @"Finding location..."

@protocol BNFBLocationManagerDelegate <NSObject>

- (void)locationUpdated;

@end

@interface BNFBLocationManager : NSObject <CLLocationManagerDelegate, FBPlacePickerDelegate, FBViewControllerDelegate>

@property (nonatomic, strong) id<FBGraphPlace> location;
@property (nonatomic, strong) NSString *locationStatus;
@property (nonatomic, weak) id <BNFBLocationManagerDelegate> delegate;
@property (nonatomic, strong) BNPlacePickerViewController *placePickerViewController;

- (id)initWithDelegate:(id<BNFBLocationManagerDelegate>)delegate;
- (void) beginUpdatingLocation;
- (void) stopUpdatingLocation:(NSString *)state;
- (void) showPlacePickerViewController;

@end

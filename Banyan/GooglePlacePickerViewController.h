//
//  GooglePlacePickerViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 1/28/14.
//
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "GooglePlacesObject.h"

@protocol GooglePlacesViewControllerDelegate <NSObject>

- (void)googlePlacesViewControllerPickedLocation:(BNDuckTypedObject<GooglePlacesObject>*)place;

- (CLLocation *)currentLocation;
@end

@interface GooglePlacePickerViewController : UIViewController

@property (nonatomic, weak) id <GooglePlacesViewControllerDelegate> delegate;

@end

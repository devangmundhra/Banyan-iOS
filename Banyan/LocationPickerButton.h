//
//  LocationPickerButton.h
//  Banyan
//
//  Created by Devang Mundhra on 3/30/13.
//
//

#import <UIKit/UIKit.h>
#import "GooglePlacesObject.h"

@class LocationPickerButton;

@protocol LocationPickerButtonDelegate <NSObject>

- (void) locationPickerButtonTapped:(LocationPickerButton *)sender;
- (void) locationPickerButtonToggleLocationEnable:(LocationPickerButton *)sender;

@end

@interface LocationPickerButton : UIView
@property (strong, nonatomic) id<LocationPickerButtonDelegate> delegate;

- (void)locationPickerLocationUpdatedWithLocation:(GooglePlacesObject *)newLocation;
- (void)locationPickerLocationEnabled:(BOOL)enable;
- (void)setLocationPickerTitle:(NSString *)locationString;
- (void)setEnabled:(BOOL)enable;
@end

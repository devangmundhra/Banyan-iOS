//
//  GooglePlacePickerTableViewCell.h
//  Banyan
//
//  Created by Devang Mundhra on 4/12/14.
//
//

#import <UIKit/UIKit.h>
#import "GooglePlacesObject.h"

@class GMSMarker;

@protocol GooglePlacePickerTableViewCellDelegate <NSObject>

- (GMSMarker *)addMarkerAtPlace:(GooglePlacesObject<GooglePlacesObject>*)place withColor:(UIColor *)color;

@end

@interface GooglePlacePickerTableViewCell : UITableViewCell

@property (nonatomic, weak) id <GooglePlacePickerTableViewCellDelegate> delegate;

- (void)setWithName:(NSString *)name place:(GooglePlacesObject<GooglePlacesObject> *)place color:(UIColor *)color markOnMap:(BOOL)markOnMap;
@end

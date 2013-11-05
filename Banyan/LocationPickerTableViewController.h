//
//  LocationPickerTableViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 12/9/12.
//
//

#import <UIKit/UIKit.h>
#import "GooglePlacesCell.h"

@protocol LocationPickerTableViewControllerDelegate <NSObject>

- (void)locationPickerTableViewControllerPickedLocation:(BNDuckTypedObject<GooglePlacesObject>*)place;

@end

@interface LocationPickerTableViewController : UITableViewController <UISearchBarDelegate>

@property (nonatomic, weak) id <LocationPickerTableViewControllerDelegate> delegate;
@property (nonatomic, strong) CLLocation        *currentLocation;

@end

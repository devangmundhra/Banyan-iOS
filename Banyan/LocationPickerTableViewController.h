//
//  LocationPickerTableViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 12/9/12.
//
//

#import <UIKit/UIKit.h>
#import "GooglePlacesObject.h"

@protocol LocationPickerTableViewControllerDelegate <NSObject>

- (void)locationPickerTableViewControllerDidCancel;
- (void)locationPickerTableViewControllerPickedLocation:(GooglePlacesObject *)place;
-(void)getGoogleObjectsWithQuery:(NSString *)query
                  andCoordinates:(CLLocationCoordinate2D)coords;
@end

@interface LocationPickerTableViewController : UITableViewController <UISearchBarDelegate>

@property (nonatomic, strong) NSMutableArray    *locationsFilterResults;
@property (nonatomic, weak) id <LocationPickerTableViewControllerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray    *locations;
@property (nonatomic, strong) CLLocation        *currentLocation;

- (void)locationManagerDidFinishLoadingWithGooglePlacesObjects:(NSMutableArray *)objects;

@end

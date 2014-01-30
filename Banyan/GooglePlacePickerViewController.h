//
//  GooglePlacePickerViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 1/28/14.
//
//

#import <UIKit/UIKit.h>
#import "GooglePlacesAnnotation.h"

@class SPGooglePlacesAutocompleteQuery;

@protocol GooglePlacesViewControllerDelegate <NSObject>

- (void)googlePlacesViewControllerPickedLocation:(BNDuckTypedObject<GooglePlacesObject>*)place;

@end

@interface GooglePlacePickerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, MKMapViewDelegate>

@property (strong, nonatomic) NSArray *searchResultPlaces;
@property (strong, nonatomic) SPGooglePlacesAutocompleteQuery *searchQuery;
@property (strong, nonatomic) GooglePlacesAnnotation *selectedPlaceAnnotation;
@property (nonatomic) BOOL shouldBeginEditing;
@property (nonatomic, weak) id <GooglePlacesViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

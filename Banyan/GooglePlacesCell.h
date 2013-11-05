//
//  GooglePlacesCell.h
//  Banyan
//
//  Created by Devang Mundhra on 11/4/13.
//
//

#import <UIKit/UIKit.h>
#import "GooglePlacesObject.h"

@interface GooglePlacesCell : UITableViewCell

- (void) setLocation:(GooglePlacesObject<GooglePlacesObject>*)place andCurrentLocation:(CLLocation *)userLoc;

@end

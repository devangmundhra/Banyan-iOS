//
//  GooglePlacesAnnotation.h
//  Banyan
//
//  Created by Devang Mundhra on 1/29/14.
//
//

#import <MapKit/MapKit.h>
#import "GooglePlacesObject.h"

@interface GooglePlacesAnnotation : MKPointAnnotation

@property (strong, nonatomic) GooglePlacesObject<GooglePlacesObject>* place;
@end

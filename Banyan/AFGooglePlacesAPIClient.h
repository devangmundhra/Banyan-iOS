//
//  AFGooglePlacesAPIClient.h
//  Banyan
//
//  Created by Devang Mundhra on 12/6/12.
//
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "GooglePlacesObject.h"

#define GOOGLE_API_NEARBY_PLACES_URL() @"nearbysearch/json"
#define GOOGLE_API_SEARCH_PLACES_URL() @"search/json"
#define GOOGLE_API_RADAR_SEARCH_PLACES_URL() @"radarsearch/json"
#define GOOGLE_API_AUTOCOMPLETE_PLACES_URL() @"autocomplete/json"
#define GOOGLE_API_PLACE_DETAIL() @"details/json?"

#define GOOGLE_API_SUCCESS_STATUS @"OK"
#define GOOGLE_API_ERROR_STATUS @"INVALID_REQUEST"
#define GOOGLE_API_NO_RESULTS_STATUS @"ZERO_RESULTS"

@interface AFGooglePlacesAPIClient : AFHTTPClient
+ (AFGooglePlacesAPIClient *)sharedClient;

typedef void (^GooglePlacesQueryCompletionBlock)(NSArray *places, NSError *error);
typedef void (^GooglePlacesPlacemarkResultBlock)(CLPlacemark *placemark, GooglePlacesObject<GooglePlacesObject>* place, NSError *error);
typedef void (^GooglePlacesAutocompleteResultBlock)(NSArray *places, NSError *error);
typedef void (^GooglePlacesPlaceDetailResultBlock)(NSDictionary *placeDictionary, NSError *error);

- (void) getNearbyLocations:(CLLocation *)location withCompletion:(GooglePlacesQueryCompletionBlock)completionBlock;
- (void) getPlacemarkForCLLocation:(CLLocation *)location withCompletion:(GooglePlacesPlacemarkResultBlock)block;
- (void) getGoogleObjectsWithQuery:(NSString *)query
                    andCoordinates:(CLLocationCoordinate2D)coords
                    withCompletion:(GooglePlacesQueryCompletionBlock)completionBlock;
- (void) autoCompletePlacesForQuery:(NSString *)query nearLocation:(CLLocation *)location
                     withCompletion:(GooglePlacesAutocompleteResultBlock)completionBlock;
- (void)getPlaceDetailsWitReference:(NSString *)reference
                     withCompletion:(GooglePlacesPlaceDetailResultBlock)completionBlock;
@end
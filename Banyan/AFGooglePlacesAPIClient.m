//
//  AFGooglePlacesAPIClient.m
//  Banyan
//
//  Created by Devang Mundhra on 12/6/12.
//
//

#import "AFGooglePlacesAPIClient.h"
#import "AFJSONRequestOperation.h"
#import "BanyanAppDelegate.h"

static NSString * const kAFGoogleAPIBaseURLString = @"https://maps.googleapis.com/maps/api/place/";

@implementation AFGooglePlacesAPIClient

+ (AFGooglePlacesAPIClient *)sharedClient {
    static AFGooglePlacesAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AFGooglePlacesAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kAFGoogleAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setParameterEncoding:AFJSONParameterEncoding];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    return self;
}

- (void)cancelOutstandingRequests
{
    [self.operationQueue cancelAllOperations];
}

static NSString *radiusString = @"500";

- (NSString *)placeTypesToConsider
{
    return [NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@",
            kBar,
            kRestaurant,
            kCafe,
            kBakery,
            kFood,
            kLodging,
            kNightClub,
            kEstablishment,
            kGeocode,
            kLodging,
            kUniversity];
}

// Autocomplete
- (void) autoCompletePlacesForQuery:(NSString *)query nearLocation:(CLLocation *)location withCompletion:(GooglePlacesAutocompleteResultBlock)completionBlock
{
    if (!query || !query.length) {
        // Don't even bother hitting Google
        completionBlock(@[], nil);
        return;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:GOOGLE_BROWSER_API_KEY forKey:@"key"];
    [parameters setObject:[query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:@"input"];
    if (location) {
        NSString *coords = [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
        [parameters setObject:coords forKey:@"location"];
    }
    [parameters setObject:radiusString forKey:@"radius"];
    [parameters setObject:@"true" forKey:@"sensor"];
    
    [self getPath:GOOGLE_API_AUTOCOMPLETE_PLACES_URL()
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *results = (NSDictionary *)responseObject;
              if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_ERROR_STATUS]) {
                  if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_NO_RESULTS_STATUS]) {
                      NSArray *gResponseData  = [results objectForKey: @"predictions"];
                      NSMutableArray *parsedPlaces = [NSMutableArray array];
                      for (NSDictionary *place in gResponseData) {
                          [parsedPlaces addObject:[GooglePlacesAutocompletePlace placeFromDictionary:place]];
                      }
                      completionBlock(parsedPlaces, nil);
                  } else {
                      completionBlock(@[], nil);
                  }
              } else {
                  [BNMisc sendGoogleAnalyticsEventWithCategory:@"Error"
                                                        action:@"Invalid Google Maps API request"
                                                         label:[NSString stringWithFormat:@"%@", parameters]
                                                         value:nil];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              completionBlock(nil, error);
              [BNMisc sendGoogleAnalyticsError:error inAction:@"GooglePlaces AutoComplete" isFatal:NO];
          }];
}

// Nearby locations
- (void) getNearbyLocations:(CLLocation *)location withCompletion:(GooglePlacesQueryCompletionBlock)completionBlock
{
    NSString *coords = [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:GOOGLE_BROWSER_API_KEY forKey:@"key"];
    [parameters setObject:coords forKey:@"location"];
    [parameters setObject:[self placeTypesToConsider] forKey:@"types"];
    [parameters setObject:radiusString forKey:@"radius"];
    //    [parameters setObject:@"distance" forKey:@"rankby"];
    [parameters setObject:@"true" forKey:@"sensor"];
    
    [self getPath:GOOGLE_API_NEARBY_PLACES_URL()
                                   parameters:parameters
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *results = (NSDictionary *)responseObject;
                                          if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_ERROR_STATUS]) {
                                              if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_NO_RESULTS_STATUS]) {
                                                  NSArray *gResponseData  = [results objectForKey: @"results"];
                                                  NSMutableArray *parsedPlaces = [NSMutableArray array];
                                                  for (NSDictionary *place in gResponseData) {
                                                      [parsedPlaces addObject:[GooglePlacesObject duckTypedObjectWrappingDictionary:place]];
                                                  }
                                                  completionBlock(parsedPlaces, nil);
                                              }
                                              else {
                                                  completionBlock(@[], nil);
                                              }
                                          } else {
                                              [BNMisc sendGoogleAnalyticsEventWithCategory:@"Error"
                                                                                    action:@"Invalid Google Maps API request"
                                                                                     label:[NSString stringWithFormat:@"%@", parameters]
                                                                                     value:nil];
                                          }
                                      }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              completionBlock(nil, error);
              [BNMisc sendGoogleAnalyticsError:error inAction:@"GooglePlaces Nearby locations" isFatal:NO];
          }];
    
    return;
}

- (void) getPlacemarkForCLLocation:(CLLocation *)location withCompletion:(GooglePlacesPlacemarkResultBlock)block
{
//    [[[CLGeocoder alloc] init] reverseGeocodeLocation:location
//                                    completionHandler:^(NSArray *placemarks, NSError *error) {
//                                        if (!error) {
//                                            CLPlacemark *placemark = [placemarks onlyObject];
//                                            GooglePlacesObject<GooglePlacesObject>* place = (GooglePlacesObject<GooglePlacesObject>*)[GooglePlacesObject duckTypedObject];
//                                            place.name = [NSString stringWithFormat:@"%@, %@", placemark.name, placemark.locality];;
//                                            place.geometry.location.lat = [NSNumber numberWithDouble:placemark.location.coordinate.latitude];
//                                            place.geometry.location.lng = [NSNumber numberWithDouble:placemark.location.coordinate.longitude];
//                                            block(placemark, place, error);
//                                        }
//                                    }];
}

// Get places for query
- (void)getGoogleObjectsWithQuery:(NSString *)query
                  andCoordinates:(CLLocationCoordinate2D)coords
                  withCompletion:(GooglePlacesQueryCompletionBlock)completionBlock
{
    assert(coords.latitude!=0 && coords.longitude!=0);
    NSString *coordsString = [NSString stringWithFormat:@"%f,%f", coords.latitude, coords.longitude];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:GOOGLE_BROWSER_API_KEY forKey:@"key"];
    [parameters setObject:coordsString forKey:@"location"];
    [parameters setObject:[self placeTypesToConsider] forKey:@"types"];
    [parameters setObject:radiusString forKey:@"radius"];
    [parameters setObject:@"true" forKey:@"sensor"];
    [parameters setObject:query forKey:@"name"];
    
    [self getPath:GOOGLE_API_SEARCH_PLACES_URL()
                                   parameters:parameters
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *results = (NSDictionary *)responseObject;
                                          if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_ERROR_STATUS]) {
                                              if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_NO_RESULTS_STATUS]) {
                                                  NSArray *gResponseData  = [results objectForKey: @"results"];
                                                  completionBlock(gResponseData, nil);
                                              }
                                              else {
                                                  completionBlock(@[], nil);
                                              }
                                          } else {
                                              [BNMisc sendGoogleAnalyticsEventWithCategory:@"Error"
                                                                                    action:@"Invalid Google Maps API request"
                                                                                     label:[NSString stringWithFormat:@"%@", parameters]
                                                                                     value:nil];
                                          }
                                      }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              completionBlock(nil, error);
              [BNMisc sendGoogleAnalyticsError:error inAction:@"GooglePlaces Search locations" isFatal:NO];
          }];
}

// Get place details
- (void)getPlaceDetailsWitReference:(NSString *)reference
                   withCompletion:(GooglePlacesPlaceDetailResultBlock)completionBlock
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:GOOGLE_BROWSER_API_KEY forKey:@"key"];
    [parameters setObject:reference forKey:@"reference"];
    [parameters setObject:@"true" forKey:@"sensor"];
    
    [self getPath:GOOGLE_API_PLACE_DETAIL()
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *results = (NSDictionary *)responseObject;
              if ([[results objectForKey:@"status"] isEqualToString:GOOGLE_API_SUCCESS_STATUS]) {
                  NSDictionary *gResponseData  = [results objectForKey: @"result"];
                  completionBlock(gResponseData, nil);
              } else {
                  [BNMisc sendGoogleAnalyticsEventWithCategory:@"Error"
                                                        action:@"Invalid Google Maps API request"
                                                         label:[NSString stringWithFormat:@"%@", parameters]
                                                         value:nil];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              completionBlock(nil, error);
              [BNMisc sendGoogleAnalyticsError:error inAction:@"GooglePlaces Search locations" isFatal:NO];
          }];
}
@end
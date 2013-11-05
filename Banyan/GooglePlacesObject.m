//
//  GooglePlacesObject.m
//  Banyan
//
//  Created by Devang Mundhra on 12/8/12.
//
//

#import "GooglePlacesObject.h"
#import "AFGoogleAPIClient.h"
#import "BanyanAppDelegate.h"

static NSString *radiusString = @"1000";

@implementation GooglePlacesObject

@synthesize placesId;
@synthesize reference;
@synthesize name;
@synthesize icon;
@synthesize rating;
@synthesize vicinity;
@synthesize types;
@synthesize url;
@synthesize address_components;
@synthesize formatted_address;
@synthesize formatted_phone_number;
@synthesize website;
@synthesize international_phone_number;
@synthesize geometry;

+ (NSString *)placeTypesToConsider
{
    return [NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@",
            kBar,
            kRestaurant,
            kCafe,
            kBakery,
            kFood,
            kLodging,
            kMealDelivery,
            kMealTakeaway,
            kNightClub,
            kEstablishment,
            kGeocode,
            kLodging,
            kUniversity];
}

# pragma mark Helper functions
- (NSString *)getFormattedName
{
    if (!self)
        return nil;
    return [NSString stringWithFormat:@"%@, %@", self.name, self.vicinity];
}

// Search
+ (void) getNearbyLocations:(CLLocation *)location withCompletion:(GooglePlacesQueryCompletionBlock)completionBlock
{
    NSString *coords = [NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:GOOGLE_API_KEY forKey:@"key"];
    [parameters setObject:coords forKey:@"location"];
    [parameters setObject:[GooglePlacesObject placeTypesToConsider] forKey:@"types"];
    [parameters setObject:radiusString forKey:@"radius"];
//    [parameters setObject:@"distance" forKey:@"rankby"];
    [parameters setObject:@"true" forKey:@"sensor"];
    
    [[AFGoogleAPIClient sharedClient] getPath:GOOGLE_API_NEARBY_PLACES_URL()
                                   parameters:parameters
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *results = (NSDictionary *)responseObject;
                                          if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_ERROR_STATUS]) {
                                              if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_NO_RESULTS_STATUS]) {
                                                  NSArray *gResponseData  = [results objectForKey: @"results"];
                                                  completionBlock(gResponseData);
                                              }
                                          } else {
                                              [TestFlight passCheckpoint:[NSString stringWithFormat:@"Invalid Google Maps API request %@", operation]];
                                          }
                                      }
                                      failure:AF_GOOGLE_ERROR_BLOCK()];
    
    return;
}

+(void)getGoogleObjectsWithQuery:(NSString *)query
                  andCoordinates:(CLLocationCoordinate2D)coords
                  withCompletion:(GooglePlacesQueryCompletionBlock)completionBlock
{
    assert(coords.latitude!=0 && coords.longitude!=0);
    NSString *coordsString = [NSString stringWithFormat:@"%f,%f", coords.latitude, coords.longitude];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:GOOGLE_API_KEY forKey:@"key"];
    [parameters setObject:coordsString forKey:@"location"];
    [parameters setObject:[GooglePlacesObject placeTypesToConsider] forKey:@"types"];
    [parameters setObject:radiusString forKey:@"radius"];
    [parameters setObject:@"true" forKey:@"sensor"];
    [parameters setObject:query forKey:@"name"];
    
    [[AFGoogleAPIClient sharedClient] getPath:GOOGLE_API_SEARCH_PLACES_URL()
                                   parameters:parameters
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *results = (NSDictionary *)responseObject;
                                          if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_ERROR_STATUS]) {
                                              if (![[results objectForKey:@"status"] isEqualToString:GOOGLE_API_NO_RESULTS_STATUS]) {
                                                  NSArray *gResponseData  = [results objectForKey: @"results"];
                                                  completionBlock(gResponseData);
                                              }
                                          } else {
                                              [TestFlight passCheckpoint:[NSString stringWithFormat:@"Invalid Google Maps API request %@", operation]];
                                          }
                                      }
                                      failure:AF_GOOGLE_ERROR_BLOCK()];
}
@end

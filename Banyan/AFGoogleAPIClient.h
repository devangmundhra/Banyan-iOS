//
//  AFGoogleAPIClient.h
//  Banyan
//
//  Created by Devang Mundhra on 12/6/12.
//
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"

#define GOOGLE_API_NEARBY_PLACES_URL() @"nearbysearch/json"
#define GOOGLE_API_SEARCH_PLACES_URL() @"search/json"
#define GOOGLE_API_RADAR_SEARCH_PLACES_URL() @"radarsearch/json"

#define GOOGLE_API_ERROR_STATUS @"INVALID_REQUEST"
#define GOOGLE_API_NO_RESULTS_STATUS @"ZERO_RESULTS"

#define AF_GOOGLE_ERROR_BLOCK() ^(AFHTTPRequestOperation *operation, NSError *error) {             \
BNLogError(@"operation: %@, response: %@, error: %@", operation, [operation responseString], error);   \
}
@interface AFGoogleAPIClient : AFHTTPClient
+ (AFGoogleAPIClient *)sharedClient;

@end

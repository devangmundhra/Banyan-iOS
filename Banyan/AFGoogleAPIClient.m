//
//  AFGoogleAPIClient.m
//  Banyan
//
//  Created by Devang Mundhra on 12/6/12.
//
//

#import "AFGoogleAPIClient.h"
#import "AFJSONRequestOperation.h"

static NSString * const kAFGoogleAPIBaseURLString = @"https://maps.googleapis.com/maps/api/place/";

@implementation AFGoogleAPIClient

+ (AFGoogleAPIClient *)sharedClient {
    static AFGoogleAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AFGoogleAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kAFGoogleAPIBaseURLString]];
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
    return self;
}
@end

//
//  AFParseAPIClient.h
//  Storied
//
//  Created by Devang Mundhra on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"

@interface AFParseAPIClient : AFHTTPClient

+ (AFParseAPIClient *)sharedClient;

@end

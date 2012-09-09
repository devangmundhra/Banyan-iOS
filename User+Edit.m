//
//  User+Edit.m
//  Banyan
//
//  Created by Devang Mundhra on 7/28/12.
//
//

#import "User+Edit.h"

@implementation User (Edit)

+ (void) editUser:(User *)user withAttributes:(NSMutableDictionary *)userParams
{
    if (!user.sessionToken) {
        NSLog(@"%s Can't find session data for user: %@", __PRETTY_FUNCTION__, user);
        NETWORK_OPERATION_COMPLETE();
        return;
    }
    
    [[AFParseAPIClient sharedClient] setDefaultHeader:@"X-Parse-Session-Token" value:user.sessionToken];
    [[AFParseAPIClient sharedClient] putPath:PARSE_API_USER_URL(user.userId)
                                  parameters:userParams
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSDictionary *response = responseObject;
                                         NSLog(@"Got response for updating user at %@", [response objectForKey:@"updatedAt"]);
                                         NETWORK_OPERATION_COMPLETE();
                                     }
                                     failure:BN_ERROR_BLOCK_OPERATION_COMPLETE()];
}

@end

//
//  User+Edit.m
//  Banyan
//
//  Created by Devang Mundhra on 7/28/12.
//
//

#import "User+Edit.h"
#import "ParseAPIEngine.h"

@implementation User (Edit)

+ (void) editUser:(PFUser *)user withAttributes:(NSMutableDictionary *)userParams
{
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_USER_URL(user.objectId)
                                                                       params:userParams
                                                                   httpMethod:@"PUT"
                                                                          ssl:YES];
    [op addHeaders:[NSDictionary dictionaryWithObject:user.sessionToken forKey:@"X-Parse-Session-Token"]];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSDictionary *response = [completedOperation responseJSON];
        NSLog(@"Got response for updating user at %@", [response objectForKey:@"updatedAt"]);
    }
             onError:PARSE_ERROR_BLOCK()];
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
}

@end

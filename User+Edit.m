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

+ (void) editUser:(User *)user withAttributes:(NSMutableDictionary *)userParams
{
    if (!user.sessionToken) {
        NSLog(@"%s Can't find session data for user: %@", __PRETTY_FUNCTION__, user);
        NETWORK_OPERATION_COMPLETE();
        return;
    }
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_USER_URL(user.userId)
                                                                       params:userParams
                                                                   httpMethod:@"PUT"
                                                                          ssl:YES];
    [op addHeaders:[NSDictionary dictionaryWithObject:user.sessionToken forKey:@"X-Parse-Session-Token"]];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSDictionary *response = [completedOperation responseJSON];
        NSLog(@"Got response for updating user at %@", [response objectForKey:@"updatedAt"]);
        NETWORK_OPERATION_COMPLETE();
    }
             onError:BN_ERROR_BLOCK_OPERATION_COMPLETE()];
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
}

+ (void) editUserNoOp:(User *)user withAttributes:(NSMutableDictionary *)userParams
{
    if (!user.sessionToken) {
        NSLog(@"%s Can't find session data for user: %@", __PRETTY_FUNCTION__, user);
        return;
    }
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_USER_URL(user.userId)
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

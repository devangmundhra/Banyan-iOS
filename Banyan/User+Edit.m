//
//  User+Edit.m
//  Banyan
//
//  Created by Devang Mundhra on 7/28/12.
//
//

#import "User+Edit.h"
#import "User+Create.h"

@implementation User (Edit)

static User *_currentUser = nil;

+ (User *)currentUser
{
    PFUser *currentUser = [PFUser currentUser];
    _currentUser = [User getUserForPfUser:currentUser
                    inManagedObjectContex:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];
    return _currentUser;
}

+ (User *)currentUserInContext:(NSManagedObjectContext *)context
{
    PFUser *currentUser = [PFUser currentUser];
    _currentUser = [User getUserForPfUser:currentUser
                    inManagedObjectContex:context];
    return _currentUser;
}

+ (BOOL)loggedIn
{
    if ([PFUser currentUser] && // Check if a user is cached
        [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) // Check if user is linked to Facebook
    {
        return YES;
    }
    return NO;
}

+ (User *)userWithId:(NSString *)id
{
    if (!id) {
        return nil;
    }
    
    if ([_currentUser.userId isEqualToString:id]) {
        return _currentUser;
    } else {
        PFUser *pfUser = [PFQuery getUserObjectWithId:id];
        return [User getUserForPfUser:pfUser
                inManagedObjectContex:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];
    }
}

+ (void) editUser:(User *)user withAttributes:(NSMutableDictionary *)userParams
{
    if (!user.sessionToken) {
        NSLog(@"%s Can't find session data for user: %@", __PRETTY_FUNCTION__, user);
        return;
    }
    
    [[AFParseAPIClient sharedClient] setDefaultHeader:@"X-Parse-Session-Token" value:user.sessionToken];
    [[AFParseAPIClient sharedClient] putPath:PARSE_API_USER_URL(user.userId)
                                  parameters:userParams
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSDictionary *response = responseObject;
                                         NSLog(@"Got response for updating user at %@", [response objectForKey:@"updatedAt"]);
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
}

@end

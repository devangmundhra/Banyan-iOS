//
//  User.m
//  Banyan
//
//  Created by Devang Mundhra on 6/6/13.
//
//

#import "User.h"
#import "RemoteObject.h"
#import "User_Defines.h"

@implementation User

@dynamic email;
@dynamic createdAt;
@dynamic facebookId;
@dynamic firstName;
@dynamic lastName;
@dynamic name;
@dynamic profilePic;
@dynamic updatedAt;
@dynamic userId;
@dynamic username;
@dynamic remoteObject;

+ (User *) newUser
{
    User *user = [NSEntityDescription insertNewObjectForEntityForName:kBNUserClassKey
                                                 inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];
    return user;
}

+ (User *)currentUser
{
    PFUser *currentUser = [PFUser currentUser];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:kBNUserClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(userId MATCHES %@)", currentUser.objectId];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    
    if (array.count == 0) {
        return [User userForPfUser:currentUser];
    } else {
        // Currently one user per remote object because otherwise there will be interdependencies between different objects.
        // This keeps it cleaner.
        return [array lastObject];
    }
}

+ (User *)userForPfUser:(PFUser *)pfUser
{
    if (!pfUser) {
        return nil;
    }
    
    User *user = [User newUser];
    user.username = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_USERNAME]);
    user.email = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_EMAIL]);
    user.firstName = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_FIRSTNAME]);
    user.lastName = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_LASTNAME]);
    user.name = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_NAME]);
    user.facebookId = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_FACEBOOK_ID]);
    user.userId = pfUser.objectId;
    
    return user;
}

+ (RKEntityMapping *) UserMappingForRK
{
    RKEntityMapping *userMapping = [RKEntityMapping mappingForEntityForName:kBNUserClassKey
                                                       inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [userMapping addAttributeMappingsFromDictionary:@{@"objectId": @"userId"}];
    [userMapping addAttributeMappingsFromArray:@[@"username", @"name", @"firstName", @"lastName", @"facebookId", @"email"]];
//    userMapping.identificationAttributes = @[@"userId"];
    
    return userMapping;
}
@end

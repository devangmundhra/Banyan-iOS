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
    
    if (array == nil) {
        return [User userForPfUser:currentUser];
    } else if (array.count == 1) {
        return [array objectAtIndex:0];
    } else {
        assert(false);
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
    [user save];
    
    return user;
}


- (void)remove {
    [[self managedObjectContext] deleteObject:self];
    [self save];
}

- (void)save
{
    NSError *error = nil;
    if (![self.managedObjectContext saveToPersistentStore:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@ in saving media", error, [error userInfo]);
        exit(-1);
    }
}

+ (RKEntityMapping *) UserMappingForRK
{
    RKEntityMapping *userMapping = [RKEntityMapping mappingForEntityForName:kBNUserClassKey
                                                       inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [userMapping addAttributeMappingsFromDictionary:@{@"objectId": @"userId"}];
    [userMapping addAttributeMappingsFromArray:@[@"username", @"name", @"firstName", @"lastName", @"facebookId", @"email"]];
    userMapping.identificationAttributes = @[@"userId"];
    
    return userMapping;
}
@end

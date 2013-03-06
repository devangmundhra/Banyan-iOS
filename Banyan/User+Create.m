//
//  User+Create.m
//  Banyan
//
//  Created by Devang Mundhra on 1/1/13.
//
//

#import "User+Create.h"
#import "User_Defines.h"

@implementation User (Create)

+ (User *)getUserForPfUser:(PFUser *)pfUser inManagedObjectContex:(NSManagedObjectContext *)context
{
    if (!pfUser) {
        return nil;
    }
    
    User *user = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kBNUserClassKey];
    request.predicate = [NSPredicate predicateWithFormat:@"userId = %@", pfUser.objectId];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"userId" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError *error = nil;
    NSArray *users = [context executeFetchRequest:request error:&error];
    
    if (!users || ([users count] > 1)) {
        NSLog(@"Error in users, should not happen");
    } else if (![users count]) {
        user = [NSEntityDescription insertNewObjectForEntityForName:kBNUserClassKey
                                             inManagedObjectContext:context];
        user.username = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_USERNAME]);
        user.emailAddress = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_EMAIL]);
        user.firstName = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_FIRSTNAME]);
        user.lastName = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_LASTNAME]);
        user.name = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_NAME]);
        user.facebookId = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_FACEBOOK_ID]);
        user.userId = pfUser.objectId;
        user.createdAt = pfUser.createdAt;
        user.updatedAt = pfUser.updatedAt;
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Error: %@", error);
            assert(false);
        }
    } else {
        user = [users lastObject];
    }
    
    return user;
}
@end

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
#import "BanyanAppDelegate.h"

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
@dynamic resourceUri;

+ (User *) newUser
{
    User *user = [NSEntityDescription insertNewObjectForEntityForName:kBNUserClassKey
                                                 inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];
    return user;
}

+ (User *)currentUser
{
    if (![BanyanAppDelegate loggedIn])
        return nil;
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:BNUserDefaultsUserInfo];
    User *user = [User newUser];
    
    user.username = [userInfo objectForKey:USER_USERNAME];
    user.email = [userInfo objectForKey:USER_EMAIL];
    user.firstName = [userInfo objectForKey:USER_FIRSTNAME];
    user.lastName = [userInfo objectForKey:USER_LASTNAME];
    user.name = [userInfo objectForKey:USER_NAME];
    user.facebookId = [[userInfo objectForKey:@"facebook"] objectForKey:@"id"];
    user.userId = [userInfo objectForKey:@"id"];
    user.resourceUri = [userInfo objectForKey:@"resource_uri"];
    
    return user;
}

+ (RKEntityMapping *) UserMappingForRKGET
{
    RKEntityMapping *userMapping = [RKEntityMapping mappingForEntityForName:kBNUserClassKey
                                                       inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [userMapping addAttributeMappingsFromDictionary:@{@"id": @"userId"}];
    [userMapping addAttributeMappingsFromArray:@[@"username", @"name", @"firstName", @"lastName", @"facebookId", @"email"]];
//    userMapping.identificationAttributes = @[@"userId"];
    
    return userMapping;
}
@end

@implementation BNSharedUser

@synthesize email;
@synthesize createdAt;
@synthesize facebookId;
@synthesize firstName;
@synthesize lastName;
@synthesize name;
@synthesize profilePic;
@synthesize updatedAt;
@synthesize userId;
@synthesize username;
@synthesize resourceUri;

+ (BNSharedUser *)currentUser
{
    if (![BanyanAppDelegate loggedIn])
        return nil;
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:BNUserDefaultsUserInfo];
    BNSharedUser *user = [[BNSharedUser alloc] init];
    
    user.username = [userInfo objectForKey:USER_USERNAME];
    user.email = [userInfo objectForKey:USER_EMAIL];
    user.firstName = [userInfo objectForKey:USER_FIRSTNAME];
    user.lastName = [userInfo objectForKey:USER_LASTNAME];
    user.name = [userInfo objectForKey:USER_NAME];
    user.facebookId = [[userInfo objectForKey:@"facebook"] objectForKey:@"facebookId"];
    user.userId = [userInfo objectForKey:@"id"];
    user.resourceUri = [userInfo objectForKey:@"resource_uri"];
    
    return user;
}

@end
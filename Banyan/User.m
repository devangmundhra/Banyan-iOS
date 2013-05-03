//
//  User.m
//  Banyan
//
//  Created by Devang Mundhra on 5/2/13.
//
//

#import "User.h"
#import "User_Defines.h"
@implementation User

@synthesize email, facebookId, firstName, lastName, name, profilePic;
@synthesize username, pieces, stories;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init]) // this needs to be [super initWithCoder:aDecoder] if the superclass implements NSCoding
    {
        email = [aDecoder decodeObjectForKey:@"email"];
        facebookId = [aDecoder decodeObjectForKey:@"facebookId"];
        firstName = [aDecoder decodeObjectForKey:@"firstName"];
        lastName = [aDecoder decodeObjectForKey:@"lastName"];
        name = [aDecoder decodeObjectForKey:@"name"];
        profilePic = [aDecoder decodeObjectForKey:@"profilePic"];
        username = [aDecoder decodeObjectForKey:@"username"];
        pieces = [aDecoder decodeObjectForKey:@"pieces"];
        stories = [aDecoder decodeObjectForKey:@"stories"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    // add [super encodeWithCoder:encoder] if the superclass implements NSCoding
    [encoder encodeObject:email forKey:@"email"];
    [encoder encodeObject:facebookId forKey:@"facebookId"];
    [encoder encodeObject:firstName forKey:@"firstName"];
    [encoder encodeObject:lastName forKey:@"lastName"];
    [encoder encodeObject:name forKey:@"name"];
    [encoder encodeObject:profilePic forKey:@"profilePic"];
    [encoder encodeObject:username forKey:@"username"];
    [encoder encodeObject:pieces forKey:@"pieces"];
    [encoder encodeObject:stories forKey:@"stories"];
}

+ (User *)userForPfUser:(PFUser *)pfUser
{
    if (!pfUser) {
        return nil;
    }
    
    User *user = [[User alloc] init];
    user.username = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_USERNAME]);
    user.email = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_EMAIL]);
    user.firstName = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_FIRSTNAME]);
    user.lastName = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_LASTNAME]);
    user.name = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_NAME]);
    user.facebookId = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_FACEBOOK_ID]);
    user.userId = pfUser.objectId;
    
    return user;
}

@end

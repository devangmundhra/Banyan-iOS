//
//  User.m
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "User.h"
#import "Piece.h"
#import "Story.h"
#import "User_Defines.h"


@implementation User

@synthesize dateCreated = _dateCreated;
@synthesize emailAddress = _emailAddress;
@synthesize facebookId = _facebookId;
@synthesize firstName = _firstName;
@synthesize lastName = _lastName;
@synthesize name = _name;
@synthesize profilePic = _profilePic;
@synthesize username = _username;
@synthesize userId = _userId;
@synthesize sessionToken = _sessionToken;

static User *_currentUser = nil;

+ (User *)currentUser
{
    PFUser *currentUser = [PFUser currentUser];
    _currentUser = [User getUserForPfUser:currentUser];
    return _currentUser;
}

+ (User *)getUserForPfUser:(PFUser *)pfUser
{
    if (!pfUser) {
        return nil;
    }
    
    User *user = [[User alloc] init];
    [pfUser fetchIfNeeded];
    user.userId = pfUser.objectId;
    user.username = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_USERNAME]);
    user.emailAddress = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_EMAIL]);
    user.firstName = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_FIRSTNAME]);
    user.lastName = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_LASTNAME]);
    user.name = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_NAME]);
    user.facebookId = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_FACEBOOK_ID]);
    return user;
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
        return [User getUserForPfUser:pfUser];
    }
}
#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeObject:self.dateCreated forKey:USER_DATE_CREATED];
    [aCoder encodeObject:self.emailAddress forKey:USER_EMAIL];
    [aCoder encodeObject:self.facebookId forKey:USER_FACEBOOK_ID];
    [aCoder encodeObject:self.firstName forKey:USER_FIRSTNAME];
    [aCoder encodeObject:self.lastName forKey:USER_LASTNAME];
    [aCoder encodeObject:self.name forKey:USER_NAME];
    [aCoder encodeObject:self.profilePic forKey:USER_PROFILEPIC];
    [aCoder encodeObject:self.username forKey:USER_USERNAME];
    [aCoder encodeObject:self.userId forKey:USER_ID];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.dateCreated = [aDecoder decodeObjectForKey:USER_DATE_CREATED];
        self.emailAddress  = [aDecoder decodeObjectForKey:USER_EMAIL];
        self.facebookId = [aDecoder decodeObjectForKey:USER_FACEBOOK_ID];
        self.firstName = [aDecoder decodeObjectForKey:USER_FIRSTNAME];
        self.lastName = [aDecoder decodeObjectForKey:USER_LASTNAME];
        self.name = [aDecoder decodeObjectForKey:USER_NAME];
        self.profilePic = [aDecoder decodeObjectForKey:USER_PROFILEPIC];
        self.username = [aDecoder decodeObjectForKey:USER_USERNAME];
        self.userId = [aDecoder decodeObjectForKey:USER_ID];
    }
    return self;
}

#pragma mark Archiving and Unarchiving operations
+ (NSString *)pathToArchiveCurrentUser
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *currentUserPath = [paths objectAtIndex:0];
    currentUserPath = [currentUserPath stringByAppendingPathComponent:@"currentUser"];
    
    return currentUserPath;
}

+ (void) archiveCurrentUser
{
    if (!_currentUser) {
        return;
    }
    
    NSString *path = [User pathToArchiveCurrentUser];
    
    BOOL success = [NSKeyedArchiver archiveRootObject:_currentUser toFile:path];
    if (!success) {
        NSLog(@"%s Error archiving current user at path: %@", __PRETTY_FUNCTION__, path);
    }
}

+ (void) unarchiveCurrentUser
{
    NSString *path = [User pathToArchiveCurrentUser];
    // Do nothing if there are no archived operations
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"%s No archived current user on disk.", __PRETTY_FUNCTION__);
        return;
    }
    
    _currentUser = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

+ (void) deleteCurrentUserFromDisk
{
    NSString *path = [User pathToArchiveCurrentUser];
    
    NSError *error = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] &&[[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        NSLog(@"%s Deleting current user from disk at path %@", __PRETTY_FUNCTION__, path);
        
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (!success) {
            NSLog(@"Error removing current user from path: %@", error.localizedDescription);
        }
    } else if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        NSLog(@"%s Archived current user can not be deleted at path %@", __PRETTY_FUNCTION__, path);
    }
}

- (BOOL)initialized
{
    // For now, user is always initialized
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{User\n id: %@ name: %@\n}", self.userId, self.name];
}

//Change so that Users can be compared
- (NSUInteger)hash
{
    return [self.userId hash];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToUser:other];
}

- (BOOL)isEqualToUser:(User *)user
{
    if (self == user)
        return YES;
    if (![self.userId isEqualToString:user.userId])
        return NO;
    return YES;
}

@end

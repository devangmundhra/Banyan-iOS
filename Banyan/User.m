//
//  User.m
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "User.h"
#import "Scene.h"
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
@synthesize scenes = _scenes;
@synthesize stories = _stories;
@synthesize scenesLiked = _scenesLiked;
@synthesize storiesLiked = _storiesLiked;
@synthesize scenesFavourited = _scenesFavourited;
@synthesize storiesFavourited = _storiesFavourited;
@synthesize scenesViewed = _scenesViewed;
@synthesize storiesViewed = _storiesViewed;
@synthesize userId = _userId;
@synthesize sessionToken = _sessionToken;

static User *_currentUser = nil;

+ (User *)currentUser
{
    if (!_currentUser) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [User unarchiveCurrentUser];
            if (!_currentUser) {
                [User updateCurrentUser];
            }
            // Need to set the session level parameters correctly
            _currentUser.sessionToken = [PFUser currentUser].sessionToken;
        });
    }
    return _currentUser;
}

+ (void)updateCurrentUser
{
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [currentUser fetch];
    }
    _currentUser = [User getUserForPfUser:currentUser];
    _currentUser.sessionToken = currentUser.sessionToken;
    if (!_currentUser) {
        // Happens when say for example the user signs out
        [User deleteCurrentUserFromDisk];
    } else {
        [User archiveCurrentUser];
    }
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
    user.scenesViewed = REPLACE_NULL_WITH_EMPTY_ARRAY([pfUser objectForKey:USER_SCENES_VIEWED]);
    user.scenesLiked = REPLACE_NULL_WITH_EMPTY_ARRAY([pfUser objectForKey:USER_SCENES_LIKED]);
    user.scenesFavourited = REPLACE_NULL_WITH_EMPTY_ARRAY([pfUser objectForKey:USER_SCENES_FAVOURITED]);
    user.storiesViewed = REPLACE_NULL_WITH_EMPTY_ARRAY([pfUser objectForKey:USER_STORIES_VIEWED]);
    user.storiesLiked = REPLACE_NULL_WITH_EMPTY_ARRAY([pfUser objectForKey:USER_STORIES_LIKED]);
    user.storiesFavourited = REPLACE_NULL_WITH_EMPTY_ARRAY([pfUser objectForKey:USER_STORIES_FAVOURITED]);
    user.facebookId = REPLACE_NULL_WITH_NIL([pfUser objectForKey:USER_FACEBOOK_ID]);
    return user;
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
- (id) initWithUsername:(NSString *)username firstName:(NSString *)firstName lastName:(NSString *)lastName name:(NSString *)name dateCreated:(NSDate *)dateCreated emailAddress:(NSString *)emailAddress profilePic:(id)profilePic stories:(NSArray *)stories scenes:(NSArray *)scenes scenesLiked:(NSArray *)scenesLiked storiesLiked:(NSArray *)storiesLiked scenesViewed:(NSArray *)scenesViewed storiesViewed:(NSArray *)storiesViewed scenesFavourited:(NSArray *)scenesFavourited storiesFavourited:(NSArray *)storiesFavourited userId:(NSString *)userId facebookId:(NSString *)facebookId
{
    if ((self = [super init])) {
        _username = username;
        _firstName = firstName;
        _lastName = lastName;
        _name = name;
        _dateCreated = dateCreated;
        _emailAddress = _emailAddress;
        _stories = _stories;
        _scenes = _scenes;
        _scenesLiked = scenesLiked;
        _storiesLiked = storiesLiked;
        _scenesViewed = scenesViewed;
        _storiesViewed = storiesViewed;
        _scenesFavourited = scenesFavourited;
        _storiesFavourited = storiesFavourited;
        _userId = userId;
        _facebookId = facebookId;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeObject:_dateCreated forKey:USER_DATE_CREATED];
    [aCoder encodeObject:_emailAddress forKey:USER_EMAIL];
    [aCoder encodeObject:_facebookId forKey:USER_FACEBOOK_ID];
    [aCoder encodeObject:_firstName forKey:USER_FIRSTNAME];
    [aCoder encodeObject:_lastName forKey:USER_LASTNAME];
    [aCoder encodeObject:_name forKey:USER_NAME];
    [aCoder encodeObject:_profilePic forKey:USER_PROFILEPIC];
    [aCoder encodeObject:_username forKey:USER_USERNAME];
    [aCoder encodeObject:_scenes forKey:USER_SCENES];
    [aCoder encodeObject:_stories forKey:USER_STORIES];
    [aCoder encodeObject:_scenesLiked forKey:USER_SCENES_LIKED];
    [aCoder encodeObject:_storiesLiked forKey:USER_STORIES_LIKED];
    [aCoder encodeObject:_scenesFavourited forKey:USER_SCENES_FAVOURITED];
    [aCoder encodeObject:_storiesFavourited forKey:USER_STORIES_FAVOURITED];
    [aCoder encodeObject:_scenesViewed forKey:USER_SCENES_VIEWED];
    [aCoder encodeObject:_storiesViewed forKey:USER_STORIES_VIEWED];
    [aCoder encodeObject:_userId forKey:USER_ID];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSDate * dateCreated = [aDecoder decodeObjectForKey:USER_DATE_CREATED];
    NSString * emailAddress  = [aDecoder decodeObjectForKey:USER_EMAIL];
    NSString * facebookId = [aDecoder decodeObjectForKey:USER_FACEBOOK_ID];
    NSString * firstName = [aDecoder decodeObjectForKey:USER_FIRSTNAME];
    NSString * lastName = [aDecoder decodeObjectForKey:USER_LASTNAME];
    NSString * name = [aDecoder decodeObjectForKey:USER_NAME];
    id profilePic = [aDecoder decodeObjectForKey:USER_PROFILEPIC];
    NSString * username = [aDecoder decodeObjectForKey:USER_USERNAME];
    NSArray *scenes = [aDecoder decodeObjectForKey:USER_SCENES];
    NSArray *stories = [aDecoder decodeObjectForKey:USER_STORIES];
    NSArray *scenesLiked = [aDecoder decodeObjectForKey:USER_SCENES_LIKED];
    NSArray *storiesLiked = [aDecoder decodeObjectForKey:USER_STORIES_LIKED];
    NSArray *scenesViewed = [aDecoder decodeObjectForKey:USER_SCENES_VIEWED];
    NSArray *storiesViewed = [aDecoder decodeObjectForKey:USER_STORIES_VIEWED];
    NSArray *scenesFavourited = [aDecoder decodeObjectForKey:USER_SCENES_FAVOURITED];
    NSArray *storiesFavourited = [aDecoder decodeObjectForKey:USER_STORIES_FAVOURITED];
    NSString *userId = [aDecoder decodeObjectForKey:USER_ID];
    
    return [self initWithUsername:username firstName:firstName lastName:lastName name:name dateCreated:dateCreated emailAddress:emailAddress profilePic:profilePic stories:stories scenes:scenes scenesLiked:scenesLiked storiesLiked:storiesLiked scenesViewed:scenesViewed storiesViewed:storiesViewed scenesFavourited:scenesFavourited storiesFavourited:storiesFavourited userId:userId facebookId:facebookId];
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

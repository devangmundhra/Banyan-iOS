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
@synthesize facebookKey = _facebookKey;
@synthesize firstName = _firstName;
@synthesize lastName = _lastName;
@synthesize name = _name;
@synthesize profilePic = _profilePic;
@synthesize username = _username;
@synthesize scenes = _scenes;
@synthesize stories = _stories;
@synthesize scenesLiked = _scenesLiked;
@synthesize storiesLiked = _storiesLiked;
@synthesize scenesFavourites = _scenesFavourites;
@synthesize storiesFavourites = _storiesFavourites;
@synthesize scenesViewed = _scenesViewed;
@synthesize storiesViewed = _storiesViewed;

#pragma mark NSCoding
- (id) initWithUsername:(NSString *)username firstName:(NSString *)firstName lastName:(NSString *)lastName name:(NSString *)name dateCreated:(NSDate *)dateCreated emailAddress:(NSString *)emailAddress facebookKey:(NSString *)facebookKey profilePic:(id)profilePic stories:(NSArray *)stories scenes:(NSArray *)scenes scenesLiked:(NSArray *)scenesLiked storiesLiked:(NSArray *)storiesLiked scenesViewed:(NSArray *)scenesViewed storiesViewed:(NSArray *)storiesViewed scenesFavourites:(NSArray *)scenesFavourites storiesFavourites:(NSArray *)storiesFavourites
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
        _scenesFavourites = scenesFavourites;
        _storiesFavourites = storiesFavourites;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeObject:_dateCreated forKey:USER_DATE_CREATED];
    [aCoder encodeObject:_emailAddress forKey:USER_EMAIL];
    [aCoder encodeObject:_facebookKey forKey:USER_FACEBOOKKEY];
    [aCoder encodeObject:_firstName forKey:USER_FIRSTNAME];
    [aCoder encodeObject:_lastName forKey:USER_LASTNAME];
    [aCoder encodeObject:_name forKey:USER_NAME];
    [aCoder encodeObject:_profilePic forKey:USER_PROFILEPIC];
    [aCoder encodeObject:_username forKey:USER_USERNAME];
    [aCoder encodeObject:_scenes forKey:USER_SCENES];
    [aCoder encodeObject:_stories forKey:USER_STORIES];
    [aCoder encodeObject:_scenesLiked forKey:USER_SCENES_LIKED];
    [aCoder encodeObject:_storiesLiked forKey:USER_STORIES_LIKED];
    [aCoder encodeObject:_scenesFavourites forKey:USER_SCENES_FAVOURITES];
    [aCoder encodeObject:_storiesFavourites forKey:USER_STORIES_FAVOURITES];
    [aCoder encodeObject:_scenesViewed forKey:USER_SCENES_VIEWED];
    [aCoder encodeObject:_storiesViewed forKey:USER_STORIES_VIEWED];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSDate * dateCreated = [aDecoder decodeObjectForKey:USER_DATE_CREATED];
    NSString * emailAddress  = [aDecoder decodeObjectForKey:USER_EMAIL];
    NSString * facebookKey = [aDecoder decodeObjectForKey:USER_FACEBOOKKEY];
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
    NSArray *scenesFavourites = [aDecoder decodeObjectForKey:USER_SCENES_FAVOURITES];
    NSArray *storiesFavourites = [aDecoder decodeObjectForKey:USER_STORIES_FAVOURITES];
    
    return [self initWithUsername:username firstName:firstName lastName:lastName name:name dateCreated:dateCreated emailAddress:emailAddress facebookKey:facebookKey profilePic:profilePic stories:stories scenes:scenes scenesLiked:scenesLiked storiesLiked:storiesLiked scenesViewed:scenesViewed storiesViewed:storiesViewed scenesFavourites:scenesFavourites storiesFavourites:storiesFavourites];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{User\n name: %@\n}", self.name];
}

////Change so that Users can be compared
//- (NSUInteger)hash
//{
//    return [self.username hash];
//}
//
//- (BOOL)isEqual:(id)other {
//    if (other == self)
//        return YES;
//    if (!other || ![other isKindOfClass:[self class]])
//        return NO;
//    return [self isEqualToUser:other];
//}
//
//- (BOOL)isEqualToUser:(User *)user
//{
//    if (self == user)
//        return YES;
//    if (![self.username isEqualToString:user.username])
//        return NO;
//    return YES;
//}
@end

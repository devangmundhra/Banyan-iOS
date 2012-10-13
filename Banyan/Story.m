//
//  Story.m
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story_Defines.h"
#import "StoryDocuments.h"
#import "Scene.h"
#import "User.h"
#import "BanyanDataSource.h"

@implementation Story

@synthesize canContribute = _canContribute;
@synthesize canView = _canView;
@synthesize isInvited = _isInvited;
@synthesize image = _image;
@synthesize lengthOfStory = _lengthOfStory;
@synthesize storyId = _storyId;
@synthesize title = _title;
@synthesize imageURL = _imageURL;
@synthesize contributors = _contributors;
@synthesize startingScene = _startingScene;
@synthesize dateCreated = _dateCreated;
@synthesize dateModified = _dateModified;
@synthesize numberOfContributors = _numberOfContributors;
@synthesize numberOfLikes = _numberOfLikes;
@synthesize numberOfViews = _numberOfViews;
@synthesize liked = _liked;
@synthesize viewed = _viewed;
@synthesize favourite = _favourite;
@synthesize scenes = _scenes;
@synthesize initialized = _initialized;
@synthesize location = _location;
@synthesize isLocationEnabled = _isLocationEnabled;
@synthesize geocodedLocation = _geocodedLocation;
@synthesize likers = _likers;
@synthesize author = _author;
@synthesize writeAccess = _writeAccess;
@synthesize readAccess = _readAccess;
// Session properties
@synthesize imageChanged = _imageChanged;
@synthesize storyBeingRead = _storyBeingRead;

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeBool:self.canContribute forKey:STORY_CAN_CONTRIBUTE];
    [aCoder encodeBool:self.canView forKey:STORY_CAN_VIEW];
    [aCoder encodeBool:self.isInvited forKey:STORY_IS_INVITED];
    [aCoder encodeObject:self.lengthOfStory forKey:STORY_LENGTH];
    [aCoder encodeObject:self.storyId forKey:STORY_ID];
    [aCoder encodeObject:self.title forKey:STORY_TITLE];
    [aCoder encodeObject:self.imageURL forKey:STORY_IMAGE_URL];
    [aCoder encodeObject:self.contributors forKey:STORY_CONTRIBUTORS];
    [aCoder encodeObject:self.readAccess forKey:STORY_READ_ACCESS];
    [aCoder encodeObject:self.writeAccess forKey:STORY_WRITE_ACCESS];
    [aCoder encodeObject:self.startingScene forKey:STORY_STARTING_SCENE];
    [aCoder encodeObject:self.dateCreated forKey:STORY_DATE_CREATED];
    [aCoder encodeObject:self.dateModified forKey:STORY_DATE_MODIFIED];
    [aCoder encodeObject:self.numberOfLikes forKey:STORY_NUM_LIKES];
    [aCoder encodeObject:self.numberOfViews forKey:STORY_NUM_VIEWS];
    [aCoder encodeObject:self.numberOfContributors forKey:STORY_NUM_CONTRIBUTORS];
    [aCoder encodeBool:self.liked forKey:STORY_LIKED];
    [aCoder encodeBool:self.viewed forKey:STORY_VIEWED];
    [aCoder encodeBool:self.favourite forKey:STORY_FAVOURITE];
    [aCoder encodeObject:self.scenes forKey:STORY_SCENES];
    [aCoder encodeObject:self.location forKey:STORY_LOCATION];
    [aCoder encodeBool:self.isLocationEnabled forKey:STORY_LOCATION_ENABLED];
    [aCoder encodeBool:self.initialized forKey:STORY_IS_INITIALIZED];
    [aCoder encodeObject:self.geocodedLocation forKey:STORY_GEOCODEDLOCATION];
    [aCoder encodeObject:self.likers forKey:STORY_LIKERS];
    [aCoder encodeObject:self.author forKey:STORY_AUTHOR];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init])) {
        self.canContribute = [aDecoder decodeBoolForKey:STORY_CAN_CONTRIBUTE];
        self.canView = [aDecoder decodeBoolForKey:STORY_CAN_VIEW];
        self.isInvited = [aDecoder decodeBoolForKey:STORY_IS_INVITED];
        self.lengthOfStory = [aDecoder decodeObjectForKey:STORY_LENGTH];
        self.storyId = [aDecoder decodeObjectForKey:STORY_ID];
        self.title = [aDecoder decodeObjectForKey:STORY_TITLE];
        self.imageURL = [aDecoder decodeObjectForKey:STORY_IMAGE_URL];
        self.contributors = [aDecoder decodeObjectForKey:STORY_CONTRIBUTORS];
        self.readAccess = [aDecoder decodeObjectForKey:STORY_READ_ACCESS];
        self.writeAccess = [aDecoder decodeObjectForKey:STORY_WRITE_ACCESS];
        self.startingScene = [aDecoder decodeObjectForKey:STORY_STARTING_SCENE];
        self.dateCreated = [aDecoder decodeObjectForKey:STORY_DATE_CREATED];
        self.dateModified = [aDecoder decodeObjectForKey:STORY_DATE_MODIFIED];
        self.numberOfLikes = [aDecoder decodeObjectForKey:STORY_NUM_LIKES];
        self.numberOfViews = [aDecoder decodeObjectForKey:STORY_NUM_VIEWS];
        self.numberOfContributors = [aDecoder decodeObjectForKey:STORY_NUM_CONTRIBUTORS];
        self.liked = [aDecoder decodeBoolForKey:STORY_LIKED];
        self.favourite = [aDecoder decodeBoolForKey:STORY_VIEWED];
        self.viewed = [aDecoder decodeBoolForKey:STORY_FAVOURITE];
        self.scenes = [aDecoder decodeObjectForKey:STORY_SCENES];
        self.location = [aDecoder decodeObjectForKey:STORY_LOCATION];
        self.isLocationEnabled = [aDecoder decodeBoolForKey:STORY_LOCATION_ENABLED];
        self.initialized = [aDecoder decodeBoolForKey:STORY_IS_INITIALIZED];
        self.geocodedLocation = [aDecoder decodeObjectForKey:STORY_GEOCODEDLOCATION];
        self.likers = [aDecoder decodeObjectForKey:STORY_LIKERS];
        self.author = [aDecoder decodeObjectForKey:STORY_AUTHOR];
    }
    return self;
}

- (NSMutableDictionary *)getAttributesInDictionary
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    CLLocationCoordinate2D coord = [self.location coordinate];
    
    [attributes setObject:self.writeAccess forKey:STORY_WRITE_ACCESS];
    [attributes setObject:self.readAccess forKey:STORY_READ_ACCESS];
    [attributes setObject:self.lengthOfStory forKey:STORY_LENGTH];
    [attributes setObject:self.title forKey:STORY_TITLE];
    [attributes setObject:REPLACE_NIL_WITH_NULL(UPDATED(self.imageURL)) forKey:STORY_IMAGE_URL];
    [attributes setObject:REPLACE_NIL_WITH_NULL(self.contributors) forKey:STORY_CONTRIBUTORS];
    [attributes setObject:self.startingScene.sceneId forKey:STORY_STARTING_SCENE];
    [attributes setObject:self.numberOfLikes forKey:STORY_NUM_LIKES];
    [attributes setObject:self.numberOfViews forKey:STORY_NUM_VIEWS];
    [attributes setObject:self.numberOfContributors forKey:STORY_NUM_CONTRIBUTORS];
    [attributes setObject:[NSNumber numberWithBool:self.isLocationEnabled] forKey:STORY_LOCATION_ENABLED];
    [attributes setObject:REPLACE_NIL_WITH_NULL(self.geocodedLocation) forKey:STORY_GEOCODEDLOCATION];
    [attributes setObject:[NSNumber numberWithDouble:coord.latitude]
                             forKey:STORY_LATITUDE];
    [attributes setObject:[NSNumber numberWithDouble:coord.longitude]
                             forKey:STORY_LONGITUDE];
    [attributes setObject:self.author.userId forKey:STORY_AUTHOR];
    
    return attributes;
}

# pragma mark Permissions management
- (void) resetPermission
{
    NSString *writeScope = [self.writeAccess objectForKey:kBNStoryPrivacyScope];
    NSString *readScope = [self.readAccess objectForKey:kBNStoryPrivacyScope];
    
    NSDictionary *writeInvitee = [self.writeAccess objectForKey:kBNStoryPrivacyInviteeList];
    NSDictionary *readInvitee = [self.readAccess objectForKey:kBNStoryPrivacyInviteeList];
    
    NSArray *writeInvitedFacebookFriends = [writeInvitee objectForKey:kBNStoryPrivacyInvitedFacebookFriends];
    NSArray *readInvitedFacebookFriends = [readInvitee objectForKey:kBNStoryPrivacyInvitedFacebookFriends];
    
    self.isInvited = NO;
    User *currentUser = [User currentUser];
    if (currentUser) {
        NSDictionary *myAttributes = [NSDictionary dictionaryWithObjectsAndKeys:currentUser.name, @"name", currentUser.facebookId, @"id", nil];
        
        if ([writeScope isEqualToString:kBNStoryPrivacyScopePublic]) {
            // Public contributors
            self.canContribute = YES;
        } else {
            self.canContribute = NO;
            for (NSDictionary *contributor in writeInvitedFacebookFriends) {
                if ([contributor isKindOfClass:[NSDictionary class]]
                    && [[contributor objectForKey:@"id"] isEqualToString:[myAttributes objectForKey:@"id"]]) {
                    self.canContribute = YES;
                    self.canView = YES;
                    self.isInvited =YES;
                    break;
                }
            }
        }
        
        if ([readScope isEqualToString:kBNStoryPrivacyScopePublic]) {
            // Public viewers
            self.canView = YES;
        } else if ([readScope isEqualToString:kBNStoryPrivacyScopeLimited]) {
            // Limited Scope. Only Facebook friends for now
            self.canView = NO;
            for (NSDictionary *viewer in readInvitedFacebookFriends) {
                if ([viewer isKindOfClass:[NSDictionary class]]
                    && [[viewer objectForKey:@"id"] isEqualToString:[myAttributes objectForKey:@"id"]]) {
                    self.canView = YES;
                    break;
                }
            }
        } else {
            // Invited viewers            
            self.canView = NO;
            for (NSDictionary *viewer in readInvitedFacebookFriends) {
                if ([viewer isKindOfClass:[NSDictionary class]]
                    && [[viewer objectForKey:@"id"] isEqualToString:[myAttributes objectForKey:@"id"]]) {
                    self.canView = YES;
                    self.isInvited = YES;
                    break;
                }
            }
        }
    }
    else {
        // Can't find user info!
        NSLog(@"%s Can't find user info", __PRETTY_FUNCTION__);
        self.canView = [readScope isEqualToString:kBNStoryPrivacyScopePublic];
        self.canContribute = NO;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{Story\n Title: %@\n Length: %@\n Starting Scene: %@\n}", self.title, self.lengthOfStory, self.startingScene];
}

// Change so that Story can be compared
- (NSUInteger)hash
{
    return [self.storyId hash];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToStory:other];
}

- (BOOL)isEqualToStory:(Story *)story
{
    if (self == story)
        return YES;
    if (![self.storyId isEqualToString:story.storyId])
        return NO;
    return YES;
}
@end

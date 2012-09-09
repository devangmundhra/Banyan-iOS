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
@synthesize invitedToContribute = _invitedToContribute;
@synthesize invitedToView = _invitedToView;
@synthesize lengthOfStory = _lengthOfStory;
@synthesize publicContributors = _publicContributors;
@synthesize publicViewers = _publicViewers;
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
// Session properties
@synthesize imageChanged = _imageChanged;
@synthesize storyBeingRead = _storyBeingRead;

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeBool:self.canContribute forKey:STORY_CAN_CONTRIBUTE];
    [aCoder encodeBool:self.canView forKey:STORY_CAN_VIEW];
    [aCoder encodeBool:self.isInvited forKey:STORY_IS_INVITED];
    [aCoder encodeObject:self.invitedToContribute forKey:STORY_INVITED_TO_CONTRIBUTE];
    [aCoder encodeObject:self.invitedToView forKey:STORY_INVITED_TO_VIEW];
    [aCoder encodeObject:self.lengthOfStory forKey:STORY_LENGTH];
    [aCoder encodeBool:self.publicContributors forKey:STORY_PUBLIC_CONTRIBUTORS];
    [aCoder encodeBool:self.publicViewers forKey:STORY_PUBLIC_VIEWERS];
    [aCoder encodeObject:self.storyId forKey:STORY_ID];
    [aCoder encodeObject:self.title forKey:STORY_TITLE];
    [aCoder encodeObject:self.imageURL forKey:STORY_IMAGE_URL];
    [aCoder encodeObject:self.contributors forKey:STORY_CONTRIBUTORS];
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
        self.invitedToContribute = [aDecoder decodeObjectForKey:STORY_INVITED_TO_CONTRIBUTE];
        self.invitedToView = [aDecoder decodeObjectForKey:STORY_INVITED_TO_VIEW];
        self.lengthOfStory = [aDecoder decodeObjectForKey:STORY_LENGTH];
        self.publicContributors = [aDecoder decodeBoolForKey:STORY_PUBLIC_CONTRIBUTORS];
        self.publicViewers = [aDecoder decodeBoolForKey:STORY_PUBLIC_VIEWERS];
        self.storyId = [aDecoder decodeObjectForKey:STORY_ID];
        self.title = [aDecoder decodeObjectForKey:STORY_TITLE];
        self.imageURL = [aDecoder decodeObjectForKey:STORY_IMAGE_URL];
        self.contributors = [aDecoder decodeObjectForKey:STORY_CONTRIBUTORS];
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
    
    [attributes setObject:REPLACE_NIL_WITH_NULL(self.invitedToContribute) forKey:STORY_INVITED_TO_CONTRIBUTE];
    [attributes setObject:REPLACE_NIL_WITH_NULL(self.invitedToView) forKey:STORY_INVITED_TO_VIEW];
    [attributes setObject:self.lengthOfStory forKey:STORY_LENGTH];
    [attributes setObject:[NSNumber numberWithBool:self.publicContributors] forKey:STORY_PUBLIC_CONTRIBUTORS];
    [attributes setObject:[NSNumber numberWithBool:self.publicViewers] forKey:STORY_PUBLIC_VIEWERS];
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

- (NSString *)description
{
    return [NSString stringWithFormat:@"{Story\n Title: %@\n Length: %@\n Starting Scene: %@\n}", self.title, self.lengthOfStory, self.startingScene];
}

//Change so that Story can be compared
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

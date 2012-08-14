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

@implementation Story

@synthesize canContribute = _canContribute;
@synthesize canView = _canView;
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
// Session properties
@synthesize imageChanged = _imageChanged;
@synthesize storyBeingRead = _storyBeingRead;

#pragma mark NSCoding

- (id) initWithTitle:(NSString *)title canContribute:(BOOL)canContribute canView:(BOOL)canView invitedToContribute:(NSArray *)invitedToContribute invitedToView:(NSArray *)invitedToView lengthOfStory:(NSNumber *)lengthOfStory publicContributors:(BOOL)publicContributors publicViewers:(BOOL)publicViewers storyId:(NSString *)storyId  imageURL:(NSString *)imageURL contributors:(NSArray *)contributors startingScene:(Scene *)startingScene createdDate:dateCreated modifiedDate:dateModified numberOfLikes:numberOfLikes numberOfViews:numberOfViews numberOfContributors:numberOfContributors liked:(BOOL)liked viewed:(BOOL)viewed favourite:(BOOL)favourite scenes:(NSArray *)scenes initialized:(BOOL) initialized location:(CLLocation *)location isLocationEnabled:(BOOL) isLocationEnabled geocodedLocation:(NSString *)geocodedLocation
{
    if ((self = [super init])) {
        _title = title;
        _canContribute = canContribute;
        _canView = canView;
        _invitedToContribute = invitedToContribute;
        _invitedToView = invitedToView;
        _lengthOfStory = lengthOfStory;
        _publicContributors = publicContributors;
        _publicViewers = publicViewers;
        _storyId = storyId;
        _imageURL = imageURL;
        _contributors = contributors;
        _startingScene = startingScene;
        _dateCreated = dateCreated;
        _dateModified = dateModified;
        _numberOfLikes = numberOfLikes;
        _numberOfViews = numberOfViews;
        _numberOfContributors = numberOfContributors;
        _liked = liked;
        _viewed = viewed;
        _favourite = favourite;
        _scenes = scenes;
        _initialized = initialized;
        _location = location;
        _isLocationEnabled = isLocationEnabled;
        _geocodedLocation = geocodedLocation;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeBool:_canContribute forKey:STORY_CAN_CONTRIBUTE];
    [aCoder encodeBool:_canView forKey:STORY_CAN_VIEW];
    [aCoder encodeObject:_invitedToContribute forKey:STORY_INVITED_TO_CONTRIBUTE];
    [aCoder encodeObject:_invitedToView forKey:STORY_INVITED_TO_VIEW];
    [aCoder encodeObject:_lengthOfStory forKey:STORY_LENGTH];
    [aCoder encodeBool:_publicContributors forKey:STORY_PUBLIC_CONTRIBUTORS];
    [aCoder encodeBool:_publicViewers forKey:STORY_PUBLIC_VIEWERS];
    [aCoder encodeObject:_storyId forKey:STORY_ID];
    [aCoder encodeObject:_title forKey:STORY_TITLE];
    [aCoder encodeObject:_imageURL forKey:STORY_IMAGE_URL];
    [aCoder encodeObject:_contributors forKey:STORY_CONTRIBUTORS];
    [aCoder encodeObject:_startingScene forKey:STORY_STARTING_SCENE];
    [aCoder encodeObject:_dateCreated forKey:STORY_DATE_CREATED];
    [aCoder encodeObject:_dateModified forKey:STORY_DATE_MODIFIED];
    [aCoder encodeObject:_numberOfLikes forKey:STORY_NUM_LIKES];
    [aCoder encodeObject:_numberOfViews forKey:STORY_NUM_VIEWS];
    [aCoder encodeObject:_numberOfContributors forKey:STORY_NUM_CONTRIBUTORS];
    [aCoder encodeBool:_liked forKey:STORY_LIKED];
    [aCoder encodeBool:_viewed forKey:STORY_VIEWED];
    [aCoder encodeBool:_favourite forKey:STORY_FAVOURITE];
    [aCoder encodeObject:_scenes forKey:STORY_SCENES];
    [aCoder encodeObject:_location forKey:STORY_LOCATION];
    [aCoder encodeBool:_isLocationEnabled forKey:STORY_LOCATION_ENABLED];
    [aCoder encodeBool:_initialized forKey:STORY_IS_INITIALIZED];
    [aCoder encodeObject:_geocodedLocation forKey:STORY_GEOCODEDLOCATION];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    BOOL canContribute = [aDecoder decodeBoolForKey:STORY_CAN_CONTRIBUTE];
    BOOL canView = [aDecoder decodeBoolForKey:STORY_CAN_VIEW];
    NSArray *invitedContributers = [aDecoder decodeObjectForKey:STORY_INVITED_TO_CONTRIBUTE];
    NSArray *invitedToView = [aDecoder decodeObjectForKey:STORY_INVITED_TO_VIEW];
    NSNumber *lengthOfStory = [aDecoder decodeObjectForKey:STORY_LENGTH];
    BOOL publicContributors = [aDecoder decodeBoolForKey:STORY_PUBLIC_CONTRIBUTORS];
    BOOL publicViewers = [aDecoder decodeBoolForKey:STORY_PUBLIC_VIEWERS];
    NSString *storyId = [aDecoder decodeObjectForKey:STORY_ID];
    NSString *title = [aDecoder decodeObjectForKey:STORY_TITLE];
    NSString *imageURL = [aDecoder decodeObjectForKey:STORY_IMAGE_URL];
    NSArray *contributors = [aDecoder decodeObjectForKey:STORY_CONTRIBUTORS];
    Scene *startingScene = [aDecoder decodeObjectForKey:STORY_STARTING_SCENE];
    NSDate *dateCreated = [aDecoder decodeObjectForKey:STORY_DATE_CREATED];
    NSDate *dateModified = [aDecoder decodeObjectForKey:STORY_DATE_MODIFIED];
    NSNumber *numberOfLikes = [aDecoder decodeObjectForKey:STORY_NUM_LIKES];
    NSNumber *numberOfViews = [aDecoder decodeObjectForKey:STORY_NUM_VIEWS];
    NSNumber *numberOfContributors = [aDecoder decodeObjectForKey:STORY_NUM_CONTRIBUTORS];
    BOOL liked = [aDecoder decodeBoolForKey:STORY_LIKED];
    BOOL favourite = [aDecoder decodeBoolForKey:STORY_VIEWED];
    BOOL viewed = [aDecoder decodeBoolForKey:STORY_FAVOURITE];
    NSArray *scenes = [aDecoder decodeObjectForKey:STORY_SCENES];
    CLLocation *location = [aDecoder decodeObjectForKey:STORY_LOCATION];
    BOOL isLocationEnabled = [aDecoder decodeBoolForKey:STORY_LOCATION_ENABLED];
    BOOL initialized = [aDecoder decodeBoolForKey:STORY_IS_INITIALIZED];
    NSString *geocodedLocation = [aDecoder decodeObjectForKey:STORY_GEOCODEDLOCATION];
    
    return [self initWithTitle:title canContribute:canContribute canView:canView invitedToContribute:invitedContributers invitedToView:invitedToView lengthOfStory:lengthOfStory publicContributors:publicContributors publicViewers:publicViewers storyId:storyId imageURL:imageURL contributors:contributors startingScene:startingScene createdDate:dateCreated modifiedDate:dateModified numberOfLikes:numberOfLikes numberOfViews:numberOfViews numberOfContributors:numberOfContributors liked:liked viewed:viewed favourite:favourite scenes:scenes initialized:initialized location:location isLocationEnabled:isLocationEnabled geocodedLocation:geocodedLocation];
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
    [attributes setObject:REPLACE_NIL_WITH_NULL(self.imageURL) forKey:STORY_IMAGE_URL];
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

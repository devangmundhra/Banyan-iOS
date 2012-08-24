//
//  Scene.m
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene_Defines.h"
#import "Story.h"
#import "User.h"
#import "BanyanDataSource.h"

@implementation Scene

@synthesize image = _image;
@synthesize sceneId = _sceneId;
@synthesize sceneNumberInStory = _sceneNumberInStory;
@synthesize text = _text;
@synthesize imageURL = _imageURL;
@synthesize author = _author;
@synthesize nextScene = _nextScene;
@synthesize previousScene = _previousScene;
@synthesize dateCreated = _dateCreated;
@synthesize dateModified = _dateModified;
@synthesize numberOfContributors = _numberOfContributors;
@synthesize numberOfLikes = _numberOfLikes;
@synthesize numberOfViews = _numberOfViews;
@synthesize story = _story;
@synthesize liked = _liked;
@synthesize viewed = _viewed;
@synthesize favourite = _favourite;
@synthesize initialized = _initialized;
@synthesize location = _location;
@synthesize geocodedLocation = _geocodedLocation;
// Session properties
@synthesize imageChanged = _imageChanged;

- (id)initWithText:(NSString *)text sceneId:(NSString *)sceneId sceneNumberInStory:(NSNumber *)sceneNumberInStory imageURL:(NSString *)imageURL author:(User *)author nextScene:(Scene *)nextScene previousScene:(Scene *)previousScene createdDate:dateCreated modifiedDate:dateModified numberOfLikes:numberOfLikes numberOfViews:numberOfViews numberOfContributors:numberOfContributors story:(Story *)story liked:(BOOL)liked viewed:(BOOL)viewed favourite:(BOOL)favourite initialized:(BOOL) initialized location:(CLLocation *)location geocodedLocation:(NSString *)geocodedLocation
{
    if ((self = [super init])) {
        _text = text;
        _sceneId = sceneId;
        _sceneNumberInStory = sceneNumberInStory;
        _imageURL = imageURL;
        _author = author;
        _nextScene = nextScene;
        _previousScene = previousScene;
        _dateCreated = dateCreated;
        _dateModified = dateModified;
        _numberOfLikes = numberOfLikes;
        _numberOfViews = numberOfViews;
        _numberOfContributors = numberOfContributors;
        _story = story;
        _liked = liked;
        _viewed = viewed;
        _favourite = favourite;
        _initialized = initialized;
        _location = location;
        _geocodedLocation = geocodedLocation;
    }
    return self;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_sceneId forKey:SCENE_ID];
    [aCoder encodeObject:_sceneNumberInStory forKey:SCENE_NUMBER];
    [aCoder encodeObject:_text forKey:SCENE_TEXT];
    [aCoder encodeObject:_imageURL forKey:SCENE_IMAGE_URL];
    [aCoder encodeObject:_author forKey:SCENE_AUTHOR];
    [aCoder encodeConditionalObject:_nextScene forKey:SCENE_NEXTSCENE];
    [aCoder encodeConditionalObject:_previousScene forKey:SCENE_PREVIOUSSCENE];
    [aCoder encodeConditionalObject:_story forKey:SCENE_STORY];
    [aCoder encodeObject:_dateCreated forKey:SCENE_DATE_CREATED];
    [aCoder encodeObject:_dateModified forKey:SCENE_DATE_MODIFIED];
    [aCoder encodeObject:_numberOfLikes forKey:SCENE_NUM_LIKES];
    [aCoder encodeObject:_numberOfViews forKey:SCENE_NUM_VIEWS];
    [aCoder encodeObject:_numberOfContributors forKey:SCENE_NUM_CONTRIBUTORS];
    [aCoder encodeBool:_liked forKey:SCENE_LIKED];
    [aCoder encodeBool:_viewed forKey:SCENE_VIEWED];
    [aCoder encodeBool:_favourite forKey:SCENE_FAVOURITE];
    [aCoder encodeBool:_initialized forKey:SCENE_IS_INITIALIZED];
    [aCoder encodeObject:_location forKey:SCENE_LOCATION];
    [aCoder encodeObject:_geocodedLocation forKey:SCENE_GEOCODEDLOCATION];

}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *sceneId = [aDecoder decodeObjectForKey:SCENE_ID];
    NSNumber *sceneNumberInStory = [aDecoder decodeObjectForKey:SCENE_NUMBER];
    NSString *text = [aDecoder decodeObjectForKey:SCENE_TEXT];
    NSString *imageURL = [aDecoder decodeObjectForKey:SCENE_IMAGE_URL];
    User *author = [aDecoder decodeObjectForKey:SCENE_AUTHOR];
    Scene *nextScene = [aDecoder decodeObjectForKey:SCENE_NEXTSCENE];
    Scene *previousScence = [aDecoder decodeObjectForKey:SCENE_PREVIOUSSCENE];
    Story *story = [aDecoder decodeObjectForKey:SCENE_STORY];
    NSDate *dateCreated = [aDecoder decodeObjectForKey:SCENE_DATE_CREATED];
    NSDate *dateModified = [aDecoder decodeObjectForKey:SCENE_DATE_MODIFIED];
    NSNumber *numberOfLikes = [aDecoder decodeObjectForKey:SCENE_NUM_LIKES];
    NSNumber *numberOfViews = [aDecoder decodeObjectForKey:SCENE_NUM_VIEWS];
    NSNumber *numberOfContributors = [aDecoder decodeObjectForKey:SCENE_NUM_CONTRIBUTORS];
    BOOL liked = [aDecoder decodeBoolForKey:SCENE_LIKED];
    BOOL favourite = [aDecoder decodeBoolForKey:SCENE_VIEWED];
    BOOL viewed = [aDecoder decodeBoolForKey:SCENE_FAVOURITE];
    BOOL initialized = [aDecoder decodeBoolForKey:SCENE_IS_INITIALIZED];
    CLLocation *location = [aDecoder decodeObjectForKey:SCENE_LOCATION];
    NSString *geocodedLocation = [aDecoder decodeObjectForKey:SCENE_GEOCODEDLOCATION];

    
    return [self initWithText:text sceneId:sceneId sceneNumberInStory:sceneNumberInStory imageURL:imageURL author:author nextScene:nextScene previousScene:previousScence createdDate:dateCreated modifiedDate:dateModified numberOfLikes:numberOfLikes numberOfViews:numberOfViews numberOfContributors:numberOfContributors story:story liked:liked viewed:viewed favourite:favourite initialized:initialized location:location geocodedLocation:geocodedLocation];
}

- (NSMutableDictionary *)getAttributesInDictionary
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    CLLocationCoordinate2D coord = [self.location coordinate];
    
    [attributes setObject:self.text forKey:SCENE_TEXT];
    [attributes setObject:REPLACE_NIL_WITH_NULL(UPDATED(self.imageURL)) forKey:SCENE_IMAGE_URL];
//    [attributes setObject:self.author forKey:SCENE_AUTHOR];
    [attributes setObject:REPLACE_NIL_WITH_NULL(self.nextScene.sceneId) forKey:SCENE_NEXTSCENE];
    [attributes setObject:REPLACE_NIL_WITH_NULL(self.previousScene.sceneId) forKey:SCENE_PREVIOUSSCENE];
    [attributes setObject:REPLACE_NIL_WITH_NULL(self.story.storyId) forKey:SCENE_STORY];
    [attributes setObject:self.numberOfLikes forKey:SCENE_NUM_LIKES];
    [attributes setObject:self.numberOfViews forKey:SCENE_NUM_VIEWS];
    [attributes setObject:self.numberOfContributors forKey:SCENE_NUM_CONTRIBUTORS];
    [attributes setObject:[NSNumber numberWithDouble:coord.latitude]
                   forKey:SCENE_LATITUDE];
    [attributes setObject:[NSNumber numberWithDouble:coord.longitude]
                   forKey:SCENE_LONGITUDE];
    [attributes setObject:REPLACE_NIL_WITH_NULL(self.geocodedLocation) forKey:SCENE_GEOCODEDLOCATION];

    return attributes;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{Scene\n Text:%@\n Prev Scene:%@\n Next Scene:%@\n Story:%@ \n}",
            self.text, self.previousScene.text, self.nextScene.text,
            self.story.title];
}

// Change so that Scenes can be compared
- (NSUInteger)hash
{
    return [self.sceneId hash];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToScene:other];
}

- (BOOL)isEqualToScene:(Scene *)scene
{
    if (self == scene)
        return YES;
    if (![self.sceneId isEqualToString:scene.sceneId])
        return NO;
    return YES;
}
@end

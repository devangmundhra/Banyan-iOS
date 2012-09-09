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
@synthesize likers = _likers;
// Session properties
@synthesize imageChanged = _imageChanged;

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.sceneId forKey:SCENE_ID];
    [aCoder encodeObject:self.sceneNumberInStory forKey:SCENE_NUMBER];
    [aCoder encodeObject:self.text forKey:SCENE_TEXT];
    [aCoder encodeObject:self.imageURL forKey:SCENE_IMAGE_URL];
    [aCoder encodeObject:self.author forKey:SCENE_AUTHOR];
    [aCoder encodeConditionalObject:self.nextScene forKey:SCENE_NEXTSCENE];
    [aCoder encodeConditionalObject:self.previousScene forKey:SCENE_PREVIOUSSCENE];
    [aCoder encodeConditionalObject:self.story forKey:SCENE_STORY];
    [aCoder encodeObject:self.dateCreated forKey:SCENE_DATE_CREATED];
    [aCoder encodeObject:self.dateModified forKey:SCENE_DATE_MODIFIED];
    [aCoder encodeObject:self.numberOfLikes forKey:SCENE_NUM_LIKES];
    [aCoder encodeObject:self.numberOfViews forKey:SCENE_NUM_VIEWS];
    [aCoder encodeObject:self.numberOfContributors forKey:SCENE_NUM_CONTRIBUTORS];
    [aCoder encodeBool:self.liked forKey:SCENE_LIKED];
    [aCoder encodeBool:self.viewed forKey:SCENE_VIEWED];
    [aCoder encodeBool:self.favourite forKey:SCENE_FAVOURITE];
    [aCoder encodeBool:self.initialized forKey:SCENE_IS_INITIALIZED];
    [aCoder encodeObject:self.location forKey:SCENE_LOCATION];
    [aCoder encodeObject:self.geocodedLocation forKey:SCENE_GEOCODEDLOCATION];
    [aCoder encodeObject:self.likers forKey:SCENE_LIKERS];

}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init])) {
        self.sceneId = [aDecoder decodeObjectForKey:SCENE_ID];
        self.sceneNumberInStory = [aDecoder decodeObjectForKey:SCENE_NUMBER];
        self.text = [aDecoder decodeObjectForKey:SCENE_TEXT];
        self.imageURL = [aDecoder decodeObjectForKey:SCENE_IMAGE_URL];
        self.author = [aDecoder decodeObjectForKey:SCENE_AUTHOR];
        self.nextScene = [aDecoder decodeObjectForKey:SCENE_NEXTSCENE];
        self.previousScene = [aDecoder decodeObjectForKey:SCENE_PREVIOUSSCENE];
        self.story = [aDecoder decodeObjectForKey:SCENE_STORY];
        self.dateCreated = [aDecoder decodeObjectForKey:SCENE_DATE_CREATED];
        self.dateModified = [aDecoder decodeObjectForKey:SCENE_DATE_MODIFIED];
        self.numberOfLikes = [aDecoder decodeObjectForKey:SCENE_NUM_LIKES];
        self.numberOfViews = [aDecoder decodeObjectForKey:SCENE_NUM_VIEWS];
        self.numberOfContributors = [aDecoder decodeObjectForKey:SCENE_NUM_CONTRIBUTORS];
        self.liked = [aDecoder decodeBoolForKey:SCENE_LIKED];
        self.favourite = [aDecoder decodeBoolForKey:SCENE_VIEWED];
        self.viewed = [aDecoder decodeBoolForKey:SCENE_FAVOURITE];
        self.initialized = [aDecoder decodeBoolForKey:SCENE_IS_INITIALIZED];
        self.location = [aDecoder decodeObjectForKey:SCENE_LOCATION];
        self.geocodedLocation = [aDecoder decodeObjectForKey:SCENE_GEOCODEDLOCATION];
        self.likers = [aDecoder decodeObjectForKey:SCENE_LIKERS];
    }
    
    return self;
}

- (NSMutableDictionary *)getAttributesInDictionary
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    CLLocationCoordinate2D coord = [self.location coordinate];
    
    [attributes setObject:self.text forKey:SCENE_TEXT];
    [attributes setObject:REPLACE_NIL_WITH_NULL(UPDATED(self.imageURL)) forKey:SCENE_IMAGE_URL];
    [attributes setObject:self.author.userId forKey:SCENE_AUTHOR];
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

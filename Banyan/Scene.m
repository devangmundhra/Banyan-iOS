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

- (id)initWithText:(NSString *)text sceneId:(NSString *)sceneId sceneNumberInStory:(NSNumber *)sceneNumberInStory imageURL:(NSString *)imageURL author:(User *)author nextScene:(Scene *)nextScene previousScene:(Scene *)previousScene createdDate:dateCreated modifiedDate:dateModified numberOfLikes:numberOfLikes numberOfViews:numberOfViews numberOfContributors:numberOfContributors story:(Story *)story liked:(BOOL)liked viewed:(BOOL)viewed favourite:(BOOL)favourite initialized:(BOOL) initialized
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
    
    return [self initWithText:text sceneId:sceneId sceneNumberInStory:sceneNumberInStory imageURL:imageURL author:author nextScene:nextScene previousScene:previousScence createdDate:dateCreated modifiedDate:dateModified numberOfLikes:numberOfLikes numberOfViews:numberOfViews numberOfContributors:numberOfContributors story:story liked:liked viewed:viewed favourite:favourite initialized:initialized];
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

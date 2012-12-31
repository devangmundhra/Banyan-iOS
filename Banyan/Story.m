//
//  Story.m
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story_Defines.h"
#import "StoryDocuments.h"
#import "Piece.h"
#import "User.h"
#import "BanyanDataSource.h"
#import "AFBanyanAPIClient.h"
#import "AFJSONRequestOperation.h"
#import "Story+Stats.h"

@implementation Story

@synthesize canContribute = _canContribute;
@synthesize canView = _canView;
@synthesize isInvited = _isInvited;
@synthesize length = _lengthOfStory;
@synthesize storyId = _storyId;
@synthesize title = _title;
@synthesize imageURL = _imageURL;
@synthesize imageName = _imageName;
@synthesize contributors = _contributors;
@synthesize createdAt = _dateCreated;
@synthesize updatedAt = _dateModified;
@synthesize numberOfContributors = _numberOfContributors;
@synthesize numberOfLikes = _numberOfLikes;
@synthesize numberOfViews = _numberOfViews;
@synthesize liked = _liked;
@synthesize viewed = _viewed;
@synthesize favourite = _favourite;
@synthesize pieces = _scenes;
@synthesize initialized = _initialized;
@synthesize location = _location;
@synthesize isLocationEnabled = _isLocationEnabled;
@synthesize geocodedLocation = _geocodedLocation;
@synthesize likers = _likers;
@synthesize author = _author;
@synthesize writeAccess = _writeAccess;
@synthesize readAccess = _readAccess;
@synthesize tags = _tags;
@synthesize latitude = _latitude;
@synthesize longitude = _longitude;

// Session properties
@synthesize imageChanged = _imageChanged;
@synthesize storyBeingRead = _storyBeingRead;

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeBool:self.canContribute forKey:STORY_CAN_CONTRIBUTE];
    [aCoder encodeBool:self.canView forKey:STORY_CAN_VIEW];
    [aCoder encodeBool:self.isInvited forKey:STORY_IS_INVITED];
    [aCoder encodeObject:self.length forKey:STORY_LENGTH];
    [aCoder encodeObject:self.storyId forKey:@"storyId"];
    [aCoder encodeObject:self.title forKey:STORY_TITLE];
    [aCoder encodeObject:self.imageURL forKey:STORY_IMAGE_URL];
    [aCoder encodeObject:self.contributors forKey:STORY_CONTRIBUTORS];
    [aCoder encodeObject:self.readAccess forKey:STORY_READ_ACCESS];
    [aCoder encodeObject:self.writeAccess forKey:STORY_WRITE_ACCESS];
    [aCoder encodeObject:self.createdAt forKey:STORY_DATE_CREATED];
    [aCoder encodeObject:self.updatedAt forKey:STORY_DATE_MODIFIED];
    [aCoder encodeObject:self.numberOfLikes forKey:STORY_NUM_LIKES];
    [aCoder encodeObject:self.numberOfViews forKey:STORY_NUM_VIEWS];
    [aCoder encodeObject:self.numberOfContributors forKey:STORY_NUM_CONTRIBUTORS];
    [aCoder encodeBool:self.liked forKey:STORY_LIKED];
    [aCoder encodeBool:self.viewed forKey:STORY_VIEWED];
    [aCoder encodeBool:self.favourite forKey:STORY_FAVOURITE];
    [aCoder encodeObject:self.pieces forKey:STORY_SCENES];
    [aCoder encodeObject:self.location forKey:STORY_LOCATION];
    [aCoder encodeBool:self.isLocationEnabled forKey:STORY_LOCATION_ENABLED];
    [aCoder encodeBool:self.initialized forKey:STORY_IS_INITIALIZED];
    [aCoder encodeObject:self.geocodedLocation forKey:STORY_GEOCODEDLOCATION];
    [aCoder encodeObject:self.likers forKey:STORY_LIKERS];
    [aCoder encodeObject:self.author forKey:STORY_AUTHOR];
    [aCoder encodeObject:self.tags forKey:STORY_TAGS];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init])) {
        self.canContribute = [aDecoder decodeBoolForKey:STORY_CAN_CONTRIBUTE];
        self.canView = [aDecoder decodeBoolForKey:STORY_CAN_VIEW];
        self.isInvited = [aDecoder decodeBoolForKey:STORY_IS_INVITED];
        self.length = [aDecoder decodeObjectForKey:STORY_LENGTH];
        self.storyId = [aDecoder decodeObjectForKey:@"storyId"];
        self.title = [aDecoder decodeObjectForKey:STORY_TITLE];
        self.imageURL = [aDecoder decodeObjectForKey:STORY_IMAGE_URL];
        self.contributors = [aDecoder decodeObjectForKey:STORY_CONTRIBUTORS];
        self.readAccess = [aDecoder decodeObjectForKey:STORY_READ_ACCESS];
        self.writeAccess = [aDecoder decodeObjectForKey:STORY_WRITE_ACCESS];
        self.createdAt = [aDecoder decodeObjectForKey:STORY_DATE_CREATED];
        self.updatedAt = [aDecoder decodeObjectForKey:STORY_DATE_MODIFIED];
        self.numberOfLikes = [aDecoder decodeObjectForKey:STORY_NUM_LIKES];
        self.numberOfViews = [aDecoder decodeObjectForKey:STORY_NUM_VIEWS];
        self.numberOfContributors = [aDecoder decodeObjectForKey:STORY_NUM_CONTRIBUTORS];
        self.liked = [aDecoder decodeBoolForKey:STORY_LIKED];
        self.favourite = [aDecoder decodeBoolForKey:STORY_VIEWED];
        self.viewed = [aDecoder decodeBoolForKey:STORY_FAVOURITE];
        self.pieces = [aDecoder decodeObjectForKey:STORY_SCENES];
        self.location = [aDecoder decodeObjectForKey:STORY_LOCATION];
        self.isLocationEnabled = [aDecoder decodeBoolForKey:STORY_LOCATION_ENABLED];
        self.initialized = [aDecoder decodeBoolForKey:STORY_IS_INITIALIZED];
        self.geocodedLocation = [aDecoder decodeObjectForKey:STORY_GEOCODEDLOCATION];
        self.likers = [aDecoder decodeObjectForKey:STORY_LIKERS];
        self.author = [aDecoder decodeObjectForKey:STORY_AUTHOR];
        self.tags = [aDecoder decodeObjectForKey:STORY_TAGS];
    }
    return self;
}

# pragma mark Permissions management
- (void) resetPermission
{    
    self.isInvited = NO;
    self.canContribute = NO;
    self.canView = NO;
    User *currentUser = [User currentUser];
    
    if (!currentUser) {
        NSLog(@"%s No current user", __PRETTY_FUNCTION__);
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"json", @"format", self.storyId, @"object_id", currentUser.userId, @"user_id", nil];
    
    [[AFBanyanAPIClient sharedClient] getPath:BANYAN_API_GET_PERMISSIONS(@"Story")
                                   parameters:parameters
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *results = (NSDictionary *)responseObject;
                                          self.canContribute = [[results objectForKey:@"write"] boolValue];
                                          self.canView = [[results objectForKey:@"read"] boolValue];
                                          self.isInvited = [[results objectForKey:@"invited"] boolValue];
                                      }
                                      failure:AF_BANYAN_ERROR_BLOCK()];
    
    return;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{Story\n Id: %@\nTitle: %@\n Length: %@\n\n}", self.storyId, self.title, self.length];
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

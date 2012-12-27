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
@synthesize image = _image;
@synthesize lengthOfStory = _lengthOfStory;
@synthesize storyId = _storyId;
@synthesize title = _title;
@synthesize imageURL = _imageURL;
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

+ (RKObjectManager *)objectManager
{
    static RKObjectManager *_objectManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        
        RKObjectMapping *storyMapping = [RKObjectMapping mappingForClass:[self class]];
        [storyMapping addAttributeMappingsFromDictionary:@{
         @"read" : STORY_CAN_VIEW,
         @"write" : STORY_CAN_CONTRIBUTE,
         @"invited" : STORY_IS_INVITED,
         @"object.title" : STORY_TITLE,
         @"object.writeAccess" : STORY_WRITE_ACCESS,
         @"object.readAccess" : STORY_READ_ACCESS,
         @"object.tags" : STORY_TAGS,
         @"object.imageURL" : STORY_IMAGE_URL,
         @"object.geocodedLocation" : STORY_GEOCODEDLOCATION,
         @"object.createdAt" : @"dateCreated",
         @"object.updatedAt" : @"dateModified",
         @"object.objectId" : @"storyId",
         @"object.locationEnabled" : @"isLocationEnabled",
         }];

        //         @"object.startingScene" : @"startingScene.sceneId",
        RKObjectMapping *sceneMapping = [RKObjectMapping mappingForClass:[Piece class]];
        [sceneMapping addAttributeMappingsFromDictionary:@{
         @"startingScene" : @"sceneId"}];
        
        RKRelationshipMapping *sceneRelationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"object" toKeyPath:@"startingScene" withMapping:sceneMapping];
        [storyMapping addPropertyMapping:sceneRelationshipMapping];
        
        //         @"object.author" : @"author.userId"
        RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[User class]];
        [userMapping addAttributeMappingsFromDictionary:@{
         @"author" : @"userId"}];
        
        RKRelationshipMapping *userRelationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"object" toKeyPath:@"author" withMapping:userMapping];
        [storyMapping addPropertyMapping:userRelationshipMapping];
        
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:storyMapping
                                                                                           pathPattern:nil
                                                                                               keyPath:nil
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [_objectManager addResponseDescriptor:responseDescriptor];
    });
    
    return _objectManager;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{    
    [aCoder encodeBool:self.canContribute forKey:STORY_CAN_CONTRIBUTE];
    [aCoder encodeBool:self.canView forKey:STORY_CAN_VIEW];
    [aCoder encodeBool:self.isInvited forKey:STORY_IS_INVITED];
    [aCoder encodeObject:self.lengthOfStory forKey:STORY_LENGTH];
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
        self.lengthOfStory = [aDecoder decodeObjectForKey:STORY_LENGTH];
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
    [attributes setObject:REPLACE_NIL_WITH_EMPTY_STRING(self.tags) forKey:STORY_TAGS];
    return attributes;
}

- (void) fillAttributesFromDictionary:(NSDictionary *)dict
{
    NSDictionary *storyDict = [NSDictionary dictionaryWithDictionary:[dict objectForKey:@"object"]];
    // Fill in the story detials
    self.title = REPLACE_NULL_WITH_NIL([storyDict objectForKey:STORY_TITLE]);
    self.readAccess = [storyDict objectForKey:STORY_READ_ACCESS];
    self.writeAccess = [storyDict objectForKey:STORY_WRITE_ACCESS];
    self.storyId = [dict objectForKey:@"objectId"];
    self.createdAt = [dict objectForKey:@"createdAt"];
    self.updatedAt = [dict objectForKey:@"updatedAt"];
    self.author = [User getUserForPfUser:[PFQuery getUserObjectWithId:REPLACE_NULL_WITH_NIL([storyDict objectForKey:STORY_AUTHOR])]];
    [self updateStoryStats];
    
    if ([[storyDict objectForKey:STORY_LOCATION_ENABLED] isEqualToNumber:[NSNumber numberWithBool:YES]])
    {
        self.isLocationEnabled = YES;
        double latitude = [REPLACE_NULL_WITH_NIL([storyDict objectForKey:STORY_LATITUDE]) doubleValue];
        double longitude = [REPLACE_NULL_WITH_NIL([storyDict objectForKey:STORY_LONGITUDE]) doubleValue];
        self.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        self.geocodedLocation = REPLACE_NULL_WITH_NIL([storyDict objectForKey:STORY_GEOCODEDLOCATION]);
    } else
    {
        self.isLocationEnabled = NO;
    }
    self.initialized = YES;
    
    self.imageURL = REPLACE_NULL_WITH_NIL([storyDict objectForKey:STORY_IMAGE_URL]);
    self.tags = REPLACE_NULL_WITH_NIL([storyDict objectForKey:STORY_TAGS]);
    
    self.canContribute = [[dict objectForKey:@"write"] boolValue];
    self.canView = [[dict objectForKey:@"read"] boolValue];
    self.isInvited = [[dict objectForKey:@"invited"] boolValue];
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
    return [NSString stringWithFormat:@"{Story\n Id: %@\nTitle: %@\n Length: %@\n\n}", self.storyId, self.title, self.lengthOfStory];
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

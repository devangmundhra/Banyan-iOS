//
//  Story.h
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class Scene, User;

@interface Story : NSObject <NSCoding>

@property (assign) BOOL canContribute;
@property (assign) BOOL canView;
@property (assign) BOOL isInvited;
@property (strong, nonatomic) id image;
@property (strong, nonatomic) NSNumber * lengthOfStory;
@property (strong, nonatomic) NSString * storyId;
@property (strong, nonatomic) NSString * title;
@property (strong, nonatomic) NSString * imageURL;
@property (strong, nonatomic) NSArray *contributors;
@property (strong, nonatomic) NSDictionary *writeAccess;
@property (strong, nonatomic) NSDictionary *readAccess;
@property (strong, nonatomic) Scene *startingScene;
@property (strong, nonatomic) NSArray *scenes;
@property (strong, nonatomic) NSDate * dateCreated;
@property (strong, nonatomic) NSDate * dateModified;
@property (strong, nonatomic) NSNumber * numberOfContributors;
@property (strong, nonatomic) NSNumber * numberOfLikes;
@property (strong, nonatomic) NSNumber * numberOfViews;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSString *geocodedLocation;
@property (strong, nonatomic) User *author;
@property BOOL isLocationEnabled;
@property BOOL liked;
@property BOOL favourite;
@property BOOL viewed;
@property BOOL initialized;
@property (strong, nonatomic) NSArray *likers;

// Session variables. No need to archive
@property BOOL imageChanged;
@property BOOL storyBeingRead;

- (NSString *)description;
- (NSMutableDictionary *)getAttributesInDictionary;
- (void) fillAttributesFromDictionary:(NSDictionary *)dict;
- (void) resetPermission;

@end

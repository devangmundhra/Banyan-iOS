//
//  Story.h
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParseAPIEngine.h"
#import <CoreLocation/CoreLocation.h>

@class Scene, User;

@interface Story : NSObject <NSCoding>

@property (assign) BOOL canContribute;
@property (assign) BOOL canView;
@property (strong) id image;
@property (strong) NSArray *invitedToContribute;
@property (strong) NSArray *invitedToView;
@property (strong) NSNumber * lengthOfStory;
@property (assign) BOOL publicContributors;
@property (assign) BOOL publicViewers;
@property (strong) NSString * storyId;
@property (strong) NSString * title;
@property (strong) NSString * imageURL;
@property (strong) NSArray *contributors;
@property (strong) Scene *startingScene; // because a strong pointer is already declared for scenes
@property (strong) NSArray *scenes;
@property (strong) NSDate * dateCreated;
@property (strong) NSDate * dateModified;
@property (strong) NSNumber * numberOfContributors;
@property (strong) NSNumber * numberOfLikes;
@property (strong) NSNumber * numberOfViews;
@property (strong) CLLocation *location;
@property (strong) NSString *geocodedLocation;
@property BOOL isLocationEnabled;
@property BOOL liked;
@property BOOL favourite;
@property BOOL viewed;
@property BOOL initialized;

- (NSString *)description;

@end

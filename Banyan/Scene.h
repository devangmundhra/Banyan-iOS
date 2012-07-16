//
//  Scene.h
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParseAPIEngine.h"

@class Scene, Story, User;

@interface Scene : NSObject <NSCoding>

@property (strong) id image;
@property (strong) NSString * sceneId;
@property (strong) NSNumber * sceneNumberInStory;
@property (strong) NSString * text;
@property (strong) NSString * imageURL;
@property (strong) User *author;
@property (weak) Scene *nextScene;
@property (weak) Scene *previousScene;
@property (strong) NSDate * dateCreated;
@property (strong) NSDate * dateModified;
@property (strong) NSNumber * numberOfContributors;
@property (strong) NSNumber * numberOfLikes;
@property (strong) NSNumber * numberOfViews;
@property (weak) Story *story;
@property BOOL liked;
@property BOOL favourite;
@property BOOL viewed;
@property BOOL initialized;

- (NSString *)description;

@end

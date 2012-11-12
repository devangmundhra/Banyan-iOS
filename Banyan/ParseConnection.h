//
//  ParseConnection.h
//  Storied
//
//  Created by Devang Mundhra on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "Story.h"
#import "Scene.h"
#import "BanyanDataSource.h"

@interface ParseConnection : NSObject

+ (void)loadStoriesFromParseWithBlock:(void (^)(NSMutableArray *stories))successBlock;
+ (void) resetPermissionsForStories:(NSMutableArray *)stories;
+ (void) resetPermissionsForStory:(Story *)story;
+ (void)loadScenesForStory:(Story *)story;

@end

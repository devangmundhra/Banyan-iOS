//
//  BanyanDataSource.h
//  Banyan
//
//  Created by Devang Mundhra on 7/18/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Story.h"
#import "Scene.h"
#import "StoryDocuments.h"

#define UPDATED(__id__) [BanyanDataSource getUpdatedValueForId:__id__]

@interface BanyanDataSource : NSObject

+ (NSMutableArray *)shared;
+ (NSMutableDictionary *)hashTable;
+ (Story *)lookForStoryId:(NSString *)storyId;
+ (Scene *)lookForSceneId:(NSString *)sceneId inStoryId:(NSString *)storyId;
+ (NSString *)getUpdatedValueForId:(NSString *)oldId;
@end

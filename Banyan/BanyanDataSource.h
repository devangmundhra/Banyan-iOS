//
//  BanyanDataSource.h
//  Banyan
//
//  Created by Devang Mundhra on 7/18/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Story.h"
#import "Piece.h"
#import "File.h"
#import "User.h"
#import "StoryDocuments.h"
#import "BanyanConnection.h"

#define UPDATED(__id__) [BanyanDataSource getUpdatedValueForId:__id__]

@interface BanyanDataSource : NSObject

+ (NSMutableArray *)shared;
+ (void) setSharedDatasource:(NSArray *)array;

+ (NSMutableDictionary *)hashTable;
+ (Story *)lookForStoryId:(NSString *)storyId;
+ (Piece *)lookForSceneId:(NSString *)sceneId inStoryId:(NSString *)storyId;
+ (NSString *)getUpdatedValueForId:(NSString *)oldId;
+ (void) deleteArchives;
+ (void) archiveHashTable;

@end

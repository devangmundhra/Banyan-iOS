//
//  BanyanDataSource.m
//  Banyan
//
//  Created by Devang Mundhra on 7/18/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BanyanDataSource.h"

@implementation BanyanDataSource

static NSMutableArray *_sharedDatasource = nil;
static NSMutableDictionary *_hashTable = nil;

+ (NSMutableDictionary *)hashTable
{
    if (!_hashTable) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _hashTable = [NSMutableDictionary dictionary];
        });
    }
    return _hashTable;
}

- (void)setHashTable:(NSMutableDictionary *)hashTable
{
    NSLog(@"%s Hash table cannot be set", __PRETTY_FUNCTION__);
    assert(false);
}

+ (NSMutableArray *)shared
{
    if (!_sharedDatasource) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedDatasource = [NSMutableArray array];
        });
    }
    return _sharedDatasource;
}

+ (Story *)lookForStoryId:(NSString *)storyId
{
    storyId = UPDATED(storyId);
    for (Story *story in [BanyanDataSource shared])
    {
        // First search in data source
        if ([story.storyId isEqualToString:storyId]) {
            return story;
        }
    }
    
    // Now search in the documents
    // Returns nil if the story is not available in disk as well
    return [StoryDocuments loadStoryFromDisk:storyId];
}

+ (Scene *)lookForSceneId:(NSString *)sceneId inStoryId:(NSString *)storyId
{
    storyId = UPDATED(storyId);
    sceneId = UPDATED(sceneId);

    Story *story = [BanyanDataSource lookForStoryId:storyId];
    for (Scene *scene in story.scenes) {
        if ([scene.sceneId isEqualToString:sceneId]) {
            return scene;
        }
    }
    return nil;
}

+ (NSString *)getUpdatedValueForId:(NSString *)oldId
{
    NSMutableDictionary *ht = [BanyanDataSource hashTable];
    if ([ht objectForKey:oldId]) {
        return [ht objectForKey:oldId];
    }
    return oldId;
}

@end

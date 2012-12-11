//
//  BanyanDataSource.m
//  Banyan
//
//  Created by Devang Mundhra on 7/18/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BanyanDataSource.h"
#import "BanyanConnection.h"
#import "ParseConnection.h"
#import "UserManagementModule.h"

@implementation BanyanDataSource

static NSMutableArray *_sharedDatasource = nil;
static NSMutableDictionary *_hashTable = nil;

+ (void)initialize
{
    // Notifications to handle permission controls
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogInNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogOutNotification
                                               object:nil];
}

+ (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (NSMutableDictionary *)hashTable
{
    if (!_hashTable) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _hashTable = [BanyanDataSource unarchiveOperations];
            if (!_hashTable) {
                _hashTable = [NSMutableDictionary dictionary];
            }
            NSLog(@"ONE TIME HASHTABLE:\n%@", _hashTable);
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

+ (void) setSharedDatasource:(NSArray *)array
{
    [_sharedDatasource setArray:array];
}

+ (Story *)lookForStoryId:(NSString *)storyId
{
    storyId = UPDATED(storyId);
    for (Story *story in [BanyanDataSource shared])
    {
        // First search in data source
        if ([UPDATED(story.storyId) isEqualToString:storyId]) {
            NSLog(@"%s Found story %p for id: %@", __PRETTY_FUNCTION__, story, storyId);
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
    if (!story.scenes) {
        [ParseConnection loadScenesForStory:story];
    }
    if (!story.scenes) {
        [[BanyanDataSource shared] removeObject:story];
        
        story = [StoryDocuments loadStoryFromDisk:storyId];
        [[BanyanDataSource shared] addObject:story];
        NSLog(@"%s There were no scenes. So getting them again.", __PRETTY_FUNCTION__);
    }
    for (Scene *scene in story.scenes) {
        if ([UPDATED(scene.sceneId) isEqualToString:sceneId]) {
            NSLog(@"%s Found scene %p for id: %@", __PRETTY_FUNCTION__, scene, sceneId);
            return scene;
        }
    }
    return nil;
}

+ (NSString *)getUpdatedValueForId:(NSString *)oldId
{
    NSMutableDictionary *ht = [BanyanDataSource hashTable];
    NSString *newId = [ht objectForKey:oldId];
    if (newId) {
        return newId;
    }
    return oldId;
}


# pragma Storing the stories for this app
+ (void) userLoginStatusChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:BNUserLogOutNotification]) {
        [BanyanConnection resetPermissionsForStories:_sharedDatasource];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:BNDataSourceUpdatedNotification
                                                                object:self];
        });
    } else if ([[notification name] isEqualToString:BNUserLogInNotification]) {
        [self loadDataSource];
    } else {
        NSLog(@"%s Unknown notification %@", __PRETTY_FUNCTION__, [notification name]);
    }
}

+ (void) loadDataSource
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(canView == YES) OR (canContribute == YES)"];
    
    [BanyanConnection
     loadStoriesFromBanyanWithBlock:^(NSMutableArray *retValue) {
         [retValue filterUsingPredicate:predicate];
         NSLog(@"%s loadDataSource completed", __PRETTY_FUNCTION__);
         _sharedDatasource = retValue;
         dispatch_async(dispatch_get_main_queue(), ^{
             [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
             [[NSNotificationCenter defaultCenter] postNotificationName:BNDataSourceUpdatedNotification
                                                                 object:self];
         });
     }];
}

#pragma mark Archiving and Unarchiving hashtable
+ (NSString *)pathToArchivedHashTable
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *htPath = [paths objectAtIndex:0];
    htPath = [htPath stringByAppendingPathComponent:@"BanyanDataSourceHT"];
    
    return htPath;
}

+ (void) archiveHashTable
{
    if (![_hashTable count]) {
        return;
    }
    
    NSString *path = [BanyanDataSource pathToArchivedHashTable];
    
    NSLog(@"%s Archiving hash table %@", __PRETTY_FUNCTION__, _hashTable);
    BOOL success = [NSKeyedArchiver archiveRootObject:_hashTable toFile:path];
    if (!success) {
        NSLog(@"%s Error archiving hash table at path: %@", __PRETTY_FUNCTION__, path);
    }
}

+ (NSMutableDictionary *) unarchiveOperations
{
    NSString *path = [BanyanDataSource pathToArchivedHashTable];
    // Do nothing if there are no archived operations
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"%s No archived hash table.", __PRETTY_FUNCTION__);
        return nil;
    }
    
    NSMutableDictionary *archive = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    if ([archive count] == 0) {
        [BanyanDataSource deleteArchives];
        return nil;
    }
    return archive;
}

+ (void) deleteArchives
{
    NSString *path = [BanyanDataSource pathToArchivedHashTable];
    
    NSError *error = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] && [[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        NSLog(@"%s Deleting archived hash table at path %@", __PRETTY_FUNCTION__, path);
        
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (!success) {
            NSLog(@"Error removing hash table operations at path: %@", error.localizedDescription);
        }
    } else if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        NSLog(@"%s Archived hash table can not be deleted at path %@", __PRETTY_FUNCTION__, path);
    }
    
    [_hashTable removeAllObjects];
}

@end

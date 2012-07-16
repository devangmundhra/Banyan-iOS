//
//  StoryDocuments.m
//  Storied
//
//  Created by Devang Mundhra on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryDocuments.h"

@implementation StoryDocuments

+ (NSString *)getPathToStoryDocumentsDirectory
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"Story Documents"];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];   
    
    return documentsDirectory;
    
}

+ (NSString *)getPathToStoryDocumentWithStory:(Story *)story
{

    return [StoryDocuments getPathToStoryDocumentWithStoryId:story.storyId];
}

+ (NSString *)getPathToStoryDocumentWithStoryId:(NSString *)storyId
{
    NSString *documentsDirectory = [StoryDocuments getPathToStoryDocumentsDirectory];
    
    NSString *fileName = [NSString stringWithFormat:@"%@.story", storyId];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+ (NSMutableArray *)loadStoriesFromDisk 
{
    // Get documents dir
    NSString *documentsDirectory = [StoryDocuments getPathToStoryDocumentsDirectory];
    NSLog(@"Loading stories from %@", documentsDirectory);
    
    // Get contents of documents directory
    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:&error];
    if (files == nil) {
        NSLog(@"Error reading contents of documents directory: %@", [error localizedDescription]);
        return nil;
    }
    
    NSMutableArray *retval = [NSMutableArray arrayWithCapacity:files.count];

    for (NSString *file in files) {
        if ([file.pathExtension compare:@"story" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:file];
            Story *story = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
            [retval addObject:story];
        }
    }
    
    return retval;
}

+ (Story *)loadStoryFromDisk:(NSString *)storyId
{
    NSLog(@"%s, storyId %@", __PRETTY_FUNCTION__, storyId);
    Story *story = [NSKeyedUnarchiver unarchiveObjectWithFile:[StoryDocuments getPathToStoryDocumentWithStoryId:storyId]];

    return story;
}

+ (void)saveStoryToDisk:(Story *)story 
{
    NSString *path = [StoryDocuments getPathToStoryDocumentWithStory:story];

    BOOL success = [NSKeyedArchiver archiveRootObject:story toFile:path];
    if (!success) {
        NSLog(@"Error creating story at path: %@", path);
    }
}

+ (void)deleteStoryFromDisk:(Story *)story {
    
    NSError *error = nil;
    NSString *path = [StoryDocuments getPathToStoryDocumentWithStory:story];
    
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        NSLog(@"%s Deleting story at path %@", __PRETTY_FUNCTION__, path);
        
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];  
        if (!success) {
            NSLog(@"Error removing story at path: %@", error.localizedDescription);
        }
    } else {
        NSLog(@"%s Story can not be deleted at path %@", __PRETTY_FUNCTION__, path);
    }
}

+ (void)deleteStoriesFromDisk 
{
    // Get documents dir
    NSString *documentsDirectory = [StoryDocuments getPathToStoryDocumentsDirectory];
    NSLog(@"Deleting stories from %@", documentsDirectory);
    
    // Get contents of documents directory
    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:&error];
    
    for (NSString *file in files) {
        if ([file.pathExtension compare:@"story" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            NSString *path = [documentsDirectory stringByAppendingPathComponent:file];
            if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
                NSLog(@"%s Deleting story at path %@", __PRETTY_FUNCTION__, path);
                
                BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];  
                if (!success) {
                    NSLog(@"Error removing story at path: %@", error.localizedDescription);
                }
            } else {
                NSLog(@"%s Story can not be deleted at path %@", __PRETTY_FUNCTION__, path);
            }
        }
    }
}

@end

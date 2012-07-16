//
//  SceneDocuments.m
//  Storied
//
//  Created by Devang Mundhra on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SceneDocuments.h"

@implementation SceneDocuments

+ (NSString *)getPathToSceneDocumentsDirectory
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"Scene Documents"];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];   
    
    return documentsDirectory;
    
}

+ (NSString *)getPathToSceneDocumentWithScene:(Scene *)scene
{
    
    return [SceneDocuments getPathToSceneDocumentWithSceneId:scene.sceneId];
}

+ (NSString *)getPathToSceneDocumentWithSceneId:(NSString *)sceneId
{
    NSString *documentsDirectory = [SceneDocuments getPathToSceneDocumentsDirectory];
    
    NSString *fileName = [NSString stringWithFormat:@"%@.scene", sceneId];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+ (NSMutableArray *)loadScenesFromDiskForStory:(Story *)story
{
    // Get documents dir
    NSString *documentsDirectory = [SceneDocuments getPathToSceneDocumentsDirectory];
    NSLog(@"Loading scenes from %@ for story %@", documentsDirectory, story.title);
    
    NSMutableArray *retval = [NSMutableArray arrayWithCapacity:[story.lengthOfStory unsignedIntValue]];
    Scene *scene = nil;

    NSString *sceneId = story.startingScene.sceneId;
    do {
        scene = [NSKeyedUnarchiver unarchiveObjectWithFile:[SceneDocuments getPathToSceneDocumentWithSceneId:sceneId]];
        [retval addObject:scene];
        scene = scene.nextScene;
        sceneId = scene.sceneId;
    } while (scene != nil);
    
    return retval;
}

+ (void)saveSceneToDisk:(Scene *)scene {
    
    NSString *path = [SceneDocuments getPathToSceneDocumentWithScene:scene];

    BOOL success = [NSKeyedArchiver archiveRootObject:scene toFile:path];
    if (!success) {
        NSLog(@"Error creating data path: %@", path);
    }
}

+ (void)deleteSceneFromDisk:(Scene *)scene {
    
    NSError *error;
    NSString *path = [SceneDocuments getPathToSceneDocumentWithScene:scene];
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (!success) {
        NSLog(@"Error removing document path: %@", error.localizedDescription);
    }
}

@end

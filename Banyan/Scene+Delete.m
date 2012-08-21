//
//  Scene+Delete.m
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene+Delete.h"
#import "Story.h"
#import "Story_Defines.h"
#import "Scene_Defines.h"
#import "StoryDocuments.h"

@implementation Scene (Delete)

+ (void) deleteSceneFromDisk:(Scene *)scene
{
    NSLog(@"%s SceneId: %@", __PRETTY_FUNCTION__, scene.sceneId);
    
    Story *story = scene.story;
    
    // Delete scene
    if (scene.image || scene.imageURL)
    {
        NSLog(@"Scene Image still needs to be deleted");
    }
    
    INCREMENT_STORY_ATTRIBUTE_OPERATION(story, STORY_LENGTH, -1);
    
    // ARCHIVE
    NSMutableArray *currentScenes = [story.scenes mutableCopy];
    [currentScenes removeObject:scene];
    story.scenes = [currentScenes copy];
    story.lengthOfStory = [NSNumber numberWithInt:([story.lengthOfStory intValue] - 1)];
    
    if (scene.nextScene != nil)
    {
        scene.previousScene.nextScene = scene.nextScene;
        scene.nextScene.previousScene = scene.previousScene;
    } else {
        scene.previousScene.nextScene = nil;
    }
    
    [StoryDocuments saveStoryToDisk:story];
    scene = nil;
}

+ (void) deleteSceneFromServerWithId:(NSString *)sceneId
{
    // PARSE
    void (^linkNextSceneAndPreviousSceneForScene)(NSDictionary *) = ^(NSDictionary *sceneParams) {
        NSString *previousSceneId = [sceneParams objectForKey:SCENE_PREVIOUSSCENE];
        NSString *nextSceneId = [sceneParams objectForKey:SCENE_NEXTSCENE];
        
        if (nextSceneId) {   
            NSMutableDictionary *nextSceneParam = [NSMutableDictionary dictionaryWithObject:nextSceneId forKey:SCENE_NEXTSCENE];
            
            [[AFParseAPIClient sharedClient] putPath:PARSE_API_OBJECT_URL(@"Scene", previousSceneId)
                                          parameters:nextSceneParam
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSLog(@"%s Next Scene for Previous Scene set", __PRETTY_FUNCTION__);
                                             }
                                             failure:AF_PARSE_ERROR_BLOCK()];
            
            NSMutableDictionary *prevSceneParam = [NSMutableDictionary dictionaryWithObject:previousSceneId forKey:SCENE_PREVIOUSSCENE];
            
            [[AFParseAPIClient sharedClient] putPath:PARSE_API_OBJECT_URL(@"Scene", nextSceneId)
                                          parameters:prevSceneParam
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSLog(@"%s Previous Scene for Next Scene set", __PRETTY_FUNCTION__);
                                             }
                                             failure:AF_PARSE_ERROR_BLOCK()];
        } else {
            NSMutableDictionary *nextSceneParam = [NSMutableDictionary dictionaryWithObject:nextSceneId forKey:SCENE_NEXTSCENE];
            
            [[AFParseAPIClient sharedClient] putPath:PARSE_API_OBJECT_URL(@"Scene", previousSceneId)
                                          parameters:nextSceneParam
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSLog(@"%s Next Scene for Previous Scene set as null", __PRETTY_FUNCTION__);
                                             }
                                             failure:AF_PARSE_ERROR_BLOCK()];
        }
    };
    
    [[AFParseAPIClient sharedClient] getPath:PARSE_API_OBJECT_URL(@"Scene", sceneId)
                                  parameters:nil
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSDictionary *sceneFields = responseObject;
                                         linkNextSceneAndPreviousSceneForScene(sceneFields);
                                         [Scene removeSceneWithId:[sceneFields objectForKey:@"objectId"]];
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
    
 
}

+ (void) removeSceneWithId:(NSString *)sceneId
{
    [[AFParseAPIClient sharedClient] deletePath:PARSE_API_OBJECT_URL(@"Scene", sceneId)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            NSLog(@"Scene with id %@ deleted", sceneId);
                                            NETWORK_OPERATION_COMPLETE();
                                        }
                                        failure:BN_ERROR_BLOCK_OPERATION_INCOMPLETE()];
}
@end

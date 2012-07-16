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

+ (void) removeScene:(Scene *)scene
{
    NSLog(@"Remove Scene %@", scene);    
    Story *story = scene.story;
    
    // PARSE
    void (^linkNextSceneAndPreviousSceneForScene)(NSDictionary *) = ^(NSDictionary *sceneParams) {
        NSString *previousSceneId = [sceneParams objectForKey:SCENE_PREVIOUSSCENE];
        NSString *nextSceneId = [sceneParams objectForKey:SCENE_NEXTSCENE];
        
        if (nextSceneId) {   
            NSMutableDictionary *nextSceneParam = [NSMutableDictionary dictionaryWithObject:nextSceneId forKey:SCENE_NEXTSCENE];
            MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", previousSceneId) 
                                                                                params:nextSceneParam
                                                                            httpMethod:@"PUT" 
                                                                                   ssl:YES];
            [op onCompletion:^(MKNetworkOperation *completedOperation) {
                NSLog(@"%s Next Scene for Previous Scene set", __PRETTY_FUNCTION__);
            }  
                     onError:PARSE_ERROR_BLOCK()];
            [[ParseAPIEngine sharedEngine] enqueueOperation:op];
            
            NSMutableDictionary *prevSceneParam = [NSMutableDictionary dictionaryWithObject:nextSceneId forKey:SCENE_PREVIOUSSCENE];
            
            op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", previousSceneId) 
                                                           params:prevSceneParam
                                                       httpMethod:@"PUT" 
                                                              ssl:YES];
            [op onCompletion:^(MKNetworkOperation *completedOperation) {
                NSLog(@"%s Next Scene for Previous Scene set", __PRETTY_FUNCTION__);
            }  
                     onError:PARSE_ERROR_BLOCK()];
            [[ParseAPIEngine sharedEngine] enqueueOperation:op];
        } else {
            NSMutableDictionary *nextSceneParam = [NSMutableDictionary dictionaryWithObject:nextSceneId forKey:SCENE_NEXTSCENE];
            MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", previousSceneId) 
                                                                               params:nextSceneParam
                                                                           httpMethod:@"PUT" 
                                                                                  ssl:YES];
            [op onCompletion:^(MKNetworkOperation *completedOperation) {
                NSLog(@"%s Next Scene for Previous Scene set", __PRETTY_FUNCTION__);
            }  
                     onError:PARSE_ERROR_BLOCK()];
            [[ParseAPIEngine sharedEngine] enqueueOperation:op];
        }
    };
    
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", scene.sceneId) 
                                                                       params:nil
                                                                   httpMethod:@"GET" 
                                                                          ssl:YES];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSDictionary *sceneFields = [completedOperation responseJSON];
        linkNextSceneAndPreviousSceneForScene(sceneFields);
        [Scene removeSceneWithId:[sceneFields objectForKey:@"objectId"]];
    }  
             onError:PARSE_ERROR_BLOCK()];
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
    
    // Delete scene
    if (scene.image || scene.imageURL)
    {
        NSLog(@"Scene Image still needs to be deleted");
    }
    
    [story incrementStoryAttribute:STORY_LENGTH byAmount:[NSNumber numberWithInt:-1]];
    
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

+ (void) removeSceneWithId:(NSString *)sceneId
{    
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", sceneId) 
                                                                       params:nil
                                                                   httpMethod:@"DELETE" 
                                                                          ssl:YES];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSLog(@"Scene with id %@ deleted", sceneId);
    }  
             onError:PARSE_ERROR_BLOCK()];
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
}
@end

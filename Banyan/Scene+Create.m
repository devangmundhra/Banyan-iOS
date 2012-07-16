//
//  Scene+Create.m
//  Storied
//
//  Created by Devang Mundhra on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene+Create.h"
#import "Scene_Defines.h"
#import "Story_Defines.h"
#import "StoryDocuments.h"
#import "ParseConnection.h"

@implementation Scene (Create)

+ (Scene *)createSceneForStory:(Story *) story
                    attributes:(NSDictionary *)attributes
                          afterScene:(Scene *)previousScene
{
    if (![[ParseAPIEngine sharedEngine] isReachable]) {
        NSLog(@"%s Can't connect to internet", __PRETTY_FUNCTION__);
        [ParseAPIEngine showNetworkUnavailableAlert];
        return NULL;
    }
    
    NSLog(@"Adding scene for story %@", story);
    
    Scene *scene = [Scene createSceneOnDiskForStory:story attributes:attributes afterScene:previousScene];
    
    [Scene createSceneOnNetworkForScene:scene story:story attributes:attributes afterScene:previousScene];

    NSLog(@"Done adding scene %@", scene);
    return scene;
}

+ (Scene *)createSceneOnDiskForStory: (Story *)story
                          attributes:(NSDictionary *)attributes
                          afterScene:(Scene *)previousScene
{
    Scene *scene = [[Scene alloc] init];
    NSString *tempId = [[NSProcessInfo processInfo] globallyUniqueString];
    
    // DISK
    scene.sceneId = tempId;
    scene.initialized = NO;
    scene.sceneNumberInStory = 0;
    scene.story = story;
    
    if (![[attributes objectForKey:SCENE_TEXT] isEqual:[NSNull null]])
        scene.text = [attributes objectForKey:SCENE_TEXT];
    if (![[attributes objectForKey:SCENE_IMAGE] isEqual:[NSNull null]])
        scene.image = [attributes objectForKey:SCENE_IMAGE];
    
    if (!previousScene) {
        // This is the starting scene of the story
        story.startingScene = scene;
        scene.previousScene = nil;
        scene.nextScene = nil;
        story.lengthOfStory = [NSNumber numberWithInt:1];
        scene.story.scenes = [NSArray arrayWithObject:scene];
    } else {
        NSUInteger indexForNewScene = [story.scenes indexOfObject:previousScene] + 1;
        
        NSMutableArray *currentScenes = [story.scenes mutableCopy];
        [currentScenes insertObject:scene atIndex:indexForNewScene];
        story.scenes = [currentScenes copy];
        scene.nextScene = previousScene.nextScene;
        scene.previousScene = previousScene;
        scene.nextScene.previousScene = scene;
        previousScene.nextScene = scene;
        scene.author = [ParseConnection getUserForPfUser:[PFUser currentUser]];
        
        scene.story.lengthOfStory = [NSNumber numberWithUnsignedInt:([scene.story.lengthOfStory unsignedIntegerValue] + 1)];
    }
    
    scene.numberOfContributors = [NSNumber numberWithInt:0];
    scene.numberOfLikes = [NSNumber numberWithInt:0];
    scene.numberOfViews = [NSNumber numberWithInt:0];

    [StoryDocuments saveStoryToDisk:story];
    
    return scene;
}

+ (void)createSceneOnNetworkForScene:(Scene *)scene
                               story:(Story *)story
                          attributes:(NSDictionary *)attributes
                          afterScene:(Scene *)previousScene
{
    // Create this Scene
    if (!story.initialized) {        
        [story addObserver:scene forKeyPath:STORY_ID 
                   options:NSKeyValueObservingOptionNew 
                   context:nil];
        NSLog(@"%s Scene doesn't have a corresponding story id", __PRETTY_FUNCTION__);
    }
    else {
        NSMutableDictionary *sceneParams = [NSMutableDictionary dictionaryWithCapacity:1];
        
        [sceneParams setObject:[attributes objectForKey:SCENE_TEXT] forKey:SCENE_TEXT];
        [sceneParams setObject:story.storyId forKey:SCENE_STORY];
        [sceneParams setObject:[NSNumber numberWithInt:0] forKey:SCENE_NUMBER];
        if (previousScene) {
            [sceneParams setObject:scene.nextScene.sceneId ? scene.nextScene.sceneId : [NSNull null] forKey:SCENE_NEXTSCENE];
            [sceneParams setObject:previousScene.sceneId ? previousScene.sceneId : [NSNull null] forKey:SCENE_PREVIOUSSCENE];
        } else {
            [sceneParams setObject:[NSNull null] forKey:SCENE_NEXTSCENE];
            [sceneParams setObject:[NSNull null] forKey:SCENE_PREVIOUSSCENE];
        }
        [sceneParams setObject:[PFUser currentUser].objectId forKey:SCENE_AUTHOR];
        
        [sceneParams setObject:[NSNumber numberWithInt:0] forKey:SCENE_NUM_LIKES];
        [sceneParams setObject:[NSNumber numberWithInt:0] forKey:SCENE_NUM_VIEWS];
        [sceneParams setObject:[NSNumber numberWithInt:0] forKey:SCENE_NUM_CONTRIBUTORS];
        
        // Get previous scene for next Scene as this scene
        void (^prevSceneForNextScene)(NSString *) = ^(NSString *thisSceneId) {
            if (![[sceneParams objectForKey:SCENE_NEXTSCENE] isEqual:[NSNull null]]) {
                // Set previous scene for Next scene as this scene
                NSString *nextSceneId = [sceneParams objectForKey:SCENE_NEXTSCENE];
                MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", nextSceneId) 
                                                          params:[NSMutableDictionary dictionaryWithObject:thisSceneId forKey:SCENE_PREVIOUSSCENE] 
                                                      httpMethod:@"PUT" 
                                                             ssl:YES];
                
                [op onCompletion:^(MKNetworkOperation *completedOperation) {
                    NSDictionary *response = [completedOperation responseJSON];
                    NSLog(@"Got response for updating story at %@", [response objectForKey:@"updatedAt"]);
                }  
                         onError:PARSE_ERROR_BLOCK()];
                [[ParseAPIEngine sharedEngine] enqueueOperation:op];
            }
        };
        
        // Get next scene for previous scene as this scene
        void (^nextSceneForPreviousScene)(NSString *) = ^(NSString *thisSceneId){
            // Set next object for previous scene as this scene
            NSString *previousSceneId = [sceneParams objectForKey:SCENE_PREVIOUSSCENE];
            MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", previousSceneId) 
                                                                               params:[NSMutableDictionary dictionaryWithObject:thisSceneId forKey:SCENE_NEXTSCENE] 
                                                                           httpMethod:@"PUT" 
                                                                                  ssl:YES];
            
            [op onCompletion:^(MKNetworkOperation *completedOperation) {
                NSDictionary *response = [completedOperation responseJSON];
                NSLog(@"Got response for updating story at %@", [response objectForKey:@"updatedAt"]);
            }  
                     onError:PARSE_ERROR_BLOCK()];
            [[ParseAPIEngine sharedEngine] enqueueOperation:op];
        };
        
        // Add image for this scene
        void (^addImageForScene)(NSString *) = ^(NSString *thisSceneId) {
            if (![[attributes objectForKey:SCENE_IMAGE] isEqual:[NSNull null]] && [attributes objectForKey:SCENE_IMAGE])
            {
                NSData *imageData = UIImagePNGRepresentation([attributes objectForKey:SCENE_IMAGE]);
                PFFile *imageFile = [PFFile fileWithName:[thisSceneId stringByAppendingString:@".png"] data:imageData];
                [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        scene.imageURL = imageFile.url;
                        NSMutableDictionary *imageURLParam = [NSMutableDictionary dictionaryWithObject:imageFile.url 
                                                                                                forKey:SCENE_IMAGE_URL];
                        MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", thisSceneId) 
                                                                  params:imageURLParam
                                                              httpMethod:@"PUT" 
                                                                     ssl:YES];
                        [op onCompletion:^(MKNetworkOperation *completedOperation) {
                            NSLog(@"Updated scene with imageURL %@", imageFile.url);
                        }  
                                 onError:PARSE_ERROR_BLOCK()];
                        [[ParseAPIEngine sharedEngine] enqueueOperation:op];
                    }
                    else {
                        NSLog(@"%s Error %@: Can't save image for scene", __PRETTY_FUNCTION__, error);
                    }
                }];
            }
        };
        
        MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_CLASS_URL(@"Scene") 
                                                                           params:sceneParams 
                                                                       httpMethod:@"POST" 
                                                                              ssl:YES];
        [op 
         onCompletion:^(MKNetworkOperation *completedOperation) {
             NSDictionary *response = [completedOperation responseJSON];
             NSLog(@"Got response for creating scene %@", [response objectForKey:@"objectId"]);
             scene.sceneId = [response objectForKey:@"objectId"];
             scene.initialized = YES;
             // Increment the length of story
             [story incrementStoryAttribute:STORY_LENGTH byAmount:[NSNumber numberWithInt:1]];
             if (previousScene) {
                 prevSceneForNextScene([response objectForKey:@"objectId"]);
                 nextSceneForPreviousScene([response objectForKey:@"objectId"]);
             } else {
                 [story startingSceneForStory:scene];
             }
             addImageForScene([response objectForKey:@"objectId"]);
         }  
         onError:PARSE_ERROR_BLOCK()];
        
        [[ParseAPIEngine sharedEngine] enqueueOperation:op];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    if (self.text)
        [attributes setObject:self.text forKey:SCENE_TEXT];
    if (self.image)
        [attributes setObject:self.image forKey:SCENE_IMAGE];
    if (self.imageURL)
        [attributes setObject:self.imageURL forKey:SCENE_IMAGE_URL];
    
    [object removeObserver:self forKeyPath:keyPath];
    [Scene createSceneOnNetworkForScene:self story:object attributes:attributes afterScene:self.previousScene];                                                                                                                      
    
    if ([keyPath isEqualToString:STORY_ID])
    {
        NSLog(@"Hey!! Look here. Story %@ got done for keyPath %@!!", change, keyPath);    
    }
}
@end

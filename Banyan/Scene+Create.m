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
                    attributes:(NSMutableDictionary *)attributes
                          afterScene:(Scene *)previousScene
{
    BNOperationObject *obj = nil;
    BNOperation *operation = nil;
    BNOperationDependency *dep = nil;
    
    if (![[ParseAPIEngine sharedEngine] isReachable]) {
        NSLog(@"%s Can't connect to internet", __PRETTY_FUNCTION__);
        [ParseAPIEngine showNetworkUnavailableAlert];
        return NULL;
    }
    
    NSLog(@"Adding scene for story %@", story);
    
    Scene *scene = [Scene createSceneOnDiskForStory:story attributes:attributes afterScene:previousScene];
    
    // Create the object and operation
    obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeScene
                                                 tempId:scene.sceneId
                                                storyId:story.storyId];

    operation = [[BNOperation alloc] initWithObject:obj
                                             action:BNOperationActionCreate
                                       dependencies:nil];
    
    if (!story.initialized) {
        // If story is not initialized, mark this operation being dependent on the initialization of the story
        BNOperationDependency *stObj = [[BNOperationDependency alloc] initWithObjectType:BNOperationObjectTypeStory
                                                                                 tempId:story.storyId
                                                                                storyId:story.storyId
                                                                                  field:SCENE_STORY];
        [operation addDependencyObject:stObj];
    }
    
    if (scene.previousScene && !scene.previousScene.initialized) {
        // If previous scene is not initialized, mark this operation being dependent on the initialization of the previous scene
        BNOperationDependency *prevObj = [[BNOperationDependency alloc] initWithObjectType:BNOperationObjectTypeScene
                                                                                    tempId:scene.previousScene.sceneId
                                                                                   storyId:story.storyId
                                                                                     field:SCENE_PREVIOUSSCENE];
        
        [operation addDependencyObject:prevObj];
    }

    if (scene.nextScene && !scene.nextScene.initialized) {
        // If next scene is not initialized, mark this operation being dependent on the initialization of the next scene
        BNOperationDependency *nextObj = [[BNOperationDependency alloc] initWithObjectType:BNOperationObjectTypeScene
                                                                                    tempId:scene.nextScene.sceneId
                                                                                   storyId:story.storyId
                                                                                     field:SCENE_NEXTSCENE];
        
        [operation addDependencyObject:nextObj];
    }
    
    [[BNOperationQueue shared] addOperation:operation];
    
    // Note order is important: First new scene is created, then update the values for scene's previous and next scenes
    if (scene.previousScene) {
        // Edit Previous Scene's Next Object
        obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeScene tempId:scene.previousScene.sceneId storyId:scene.story.storyId];
        operation = [[BNOperation alloc] initWithObject:obj action:BNOperationActionEdit dependencies:nil];
        dep = [[BNOperationDependency alloc] initWithObjectType:BNOperationObjectTypeScene tempId:scene.sceneId storyId:scene.story.storyId field:SCENE_NEXTSCENE];
        [operation addDependencyObject:dep];
        [[BNOperationQueue shared] addOperation:operation];
    }
    
    if (scene.nextScene) {
        // Edit Next Scene's Previous Object
        obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeScene tempId:scene.nextScene.sceneId storyId:scene.story.storyId];
        operation = [[BNOperation alloc] initWithObject:obj action:BNOperationActionEdit dependencies:nil];
        dep = [[BNOperationDependency alloc] initWithObjectType:BNOperationObjectTypeScene tempId:scene.sceneId storyId:scene.story.storyId field:SCENE_PREVIOUSSCENE];
        [operation addDependencyObject:dep];
        [[BNOperationQueue shared] addOperation:operation];
    }
    
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

+ (void) createSceneOnServer:(Scene *)scene
{
    NSMutableDictionary *attributes = [scene getAttributesInDictionary];
    Story *story = scene.story;
    [attributes setObject:[PFUser currentUser].objectId forKey:SCENE_AUTHOR];
    
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
                                                                       params:attributes
                                                                   httpMethod:@"POST"
                                                                          ssl:YES];
    [op
     onCompletion:^(MKNetworkOperation *completedOperation) {
         NSDictionary *response = [completedOperation responseJSON];
         NSLog(@"Got response for creating scene %@", [response objectForKey:@"objectId"]);
         NSString *newId = [response objectForKey:@"objectId"];
         NSMutableDictionary *ht = [BanyanDataSource hashTable];
         [ht setObject:newId forKey:scene.sceneId];
         scene.sceneId = newId;
         scene.initialized = YES;
         
         // Increment the length of story
         BNOperationObject *obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeStory
                                                                         tempId:story.storyId
                                                                        storyId:story.storyId];
         BNOperation *op = [[BNOperation alloc] initWithObject:obj action:BNOperationActionIncrementAttribute dependencies:nil];
         op.action.context = [NSDictionary dictionaryWithObjectsAndKeys:STORY_LENGTH, @"attribute", [NSNumber numberWithInt:1], @"amount", nil];
         [[BNOperationQueue shared] addOperation:op];
         
//         addImageForScene([response objectForKey:@"objectId"]);
         
         [StoryDocuments saveStoryToDisk:story];
         DONE_WITH_NETWORK_OPERATION();
     }
     onError:PARSE_ERROR_BLOCK()];
    
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
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
//    [Scene createSceneOnNetworkForScene:self story:object attributes:attributes afterScene:self.previousScene];                                                                                                                      
    
    if ([keyPath isEqualToString:STORY_ID])
    {
        NSLog(@"Hey!! Look here. Story %@ got done for keyPath %@!!", change, keyPath);    
    }
}
@end

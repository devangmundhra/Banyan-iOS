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
    
    NSLog(@"Adding scene for story %@", story);
    
    Scene *scene = [Scene createSceneOnDiskForStory:story attributes:attributes afterScene:previousScene];
    
    // Create the object and operation
    obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeScene
                                                 tempId:scene.sceneId
                                                storyId:story.storyId];

    operation = [[BNOperation alloc] initWithObject:obj
                                             action:BNOperationActionCreate
                                       dependencies:nil];
    
    BNOperationDependency *imageDependency = nil;
    
    if (scene.imageURL)
    {
        scene.imageChanged = NO;

        // Upload the image (ie, create a network request for that)
        BNOperationObject *imgObj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeFile
                                                                           tempId:scene.imageURL
                                                                          storyId:scene.story.storyId];
        BNOperation *imgOperation = [[BNOperation alloc] initWithObject:imgObj action:BNOperationActionCreate dependencies:nil];
        ADD_OPERATION_TO_QUEUE(imgOperation);
        
        // Create a dependency object
        imageDependency = [[BNOperationDependency alloc] initWithBNObject:imgObj
                                                                    field:SCENE_IMAGE_URL];
        [operation addDependencyObject:imageDependency];

    }
    
    if (!story.initialized) {
        // If story is not initialized, mark this operation being dependent on the initialization of the story
        BNOperationDependency *stObj = [[BNOperationDependency alloc] initWithObjectType:BNOperationObjectTypeStory
                                                                                 tempId:story.storyId
                                                                                storyId:story.storyId
                                                                                  field:SCENE_STORY];
        [operation addDependencyObject:stObj];
    } else {
        // Increment the length of story
        // If story is not yet initialized, then there is no need to increment the lenght because the create story will
        // automatically upload the correct length when it uploads.
        BNOperationObject *obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeStory
                                                                        tempId:story.storyId
                                                                       storyId:story.storyId];
        BNOperation *op = [[BNOperation alloc] initWithObject:obj action:BNOperationActionIncrementAttribute dependencies:nil];
        op.action.context = [NSDictionary dictionaryWithObjectsAndKeys:STORY_LENGTH, @"attribute", [NSNumber numberWithInt:1], @"amount", nil];
        [[BNOperationQueue shared] addOperation:op];
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
    NSString *tempId = [NSString stringWithFormat:@"temp%@", [[NSProcessInfo processInfo] globallyUniqueString]];
    
    // DISK
    scene.sceneId = tempId;
    scene.initialized = NO;
    scene.sceneNumberInStory = 0;
    scene.story = story;
    
    if (![[attributes objectForKey:SCENE_TEXT] isEqual:[NSNull null]])
        scene.text = [attributes objectForKey:SCENE_TEXT];
    if (![[attributes objectForKey:SCENE_IMAGE_URL] isEqual:[NSNull null]])
        scene.imageURL = [attributes objectForKey:SCENE_IMAGE_URL];
    
    if (story.isLocationEnabled) {
        double latitude = [[attributes objectForKey:SCENE_LATITUDE] doubleValue];
        double longitude = [[attributes objectForKey:SCENE_LONGITUDE] doubleValue];
        scene.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        scene.geocodedLocation = [attributes objectForKey:SCENE_GEOCODEDLOCATION];
    }
    
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
        scene.author = [User currentUser];
        
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
    NSLog(@"%s scene: %@", __PRETTY_FUNCTION__, scene);
    assert(scene);
    NSMutableDictionary *attributes = [scene getAttributesInDictionary];
    Story *story = scene.story;
    [attributes setObject:[User currentUser].userId forKey:SCENE_AUTHOR];
    
    [[AFParseAPIClient sharedClient] postPath:PARSE_API_CLASS_URL(@"Scene")
                                   parameters:attributes
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *response = responseObject;
                                          NSLog(@"Got response for creating scene %@", [response objectForKey:@"objectId"]);
                                          NSString *newId = [response objectForKey:@"objectId"];
                                          [[BanyanDataSource hashTable] setObject:newId forKey:scene.sceneId];
                                          [BanyanDataSource archiveHashTable];
                                          scene.sceneId = newId;
                                          scene.initialized = YES;
                                          
                                          [StoryDocuments saveStoryToDisk:story];
                                          NETWORK_OPERATION_COMPLETE();                                          
                                      }
                                      failure:BN_ERROR_BLOCK_OPERATION_INCOMPLETE()];
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

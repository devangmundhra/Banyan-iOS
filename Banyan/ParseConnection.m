//
//  ParseConnection.m
//  Storied
//
//  Created by Devang Mundhra on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ParseConnection.h"
#import "Story_Defines.h"
#import "Scene_Defines.h"
#import "User_Defines.h"
#import "StoryDocuments.h"
#import "Scene+Stats.h"
#import "Story+Stats.h"
#import "AFParseAPIClient.h"

@implementation ParseConnection

+ (void)loadStoriesFromParseWithBlock:(void (^)(NSMutableArray *stories))successBlock onCompletion:(void (^)())completionBlock
{
#define QUERY_LIMIT 10
    // If there is no internet connection, load stories from the disk
    if (![[AFParseAPIClient sharedClient] isReachable]) {
        NSMutableArray *dStories = [StoryDocuments loadStoriesFromDisk];
        successBlock(dStories);
        completionBlock();
    }
    else {
        // else
        if ([[BNOperationQueue shared] operationCount] == 0)
            [StoryDocuments deleteStoriesFromDisk];
        PFQuery *query = [PFQuery queryWithClassName:@"Story"];
        query.limit = QUERY_LIMIT;
        [query orderByDescending:@"updatedAt"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *storyArray, NSError *error) {
            dispatch_queue_t postFetchQueue = dispatch_queue_create("parse completion queue", NULL);
            dispatch_async(postFetchQueue, ^ {
                if (!error) {
                    Story *story = nil;
                    NSMutableArray *pStories = [[NSMutableArray alloc] initWithCapacity:QUERY_LIMIT];                    
                    for (PFObject *pfStory in storyArray)
                    {
                        story = [[Story alloc] init];
                        [ParseConnection fillStory:story withPfStory:pfStory];
                        if (story.canView || story.canContribute) {
                            [pStories addObject:story];
                        }
                    }
                    successBlock(pStories);
                } else {
                    NSLog(@"Error %@ in loading stories in Parse", error);
                }
                completionBlock();
            });
            dispatch_release(postFetchQueue);
        }];
    }
}

+ (void)fillStory:(Story *)story withPfStory:(PFObject *)pfStory
{
    // Fill in the story detials
    story.title = REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_TITLE]);
    story.publicViewers = [REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_PUBLIC_VIEWERS]) boolValue];
    story.publicContributors = [REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_PUBLIC_CONTRIBUTORS]) boolValue];
    story.storyId = [pfStory objectId];
    story.lengthOfStory = REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_LENGTH]);
    
    story.numberOfLikes = REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_NUM_LIKES]);
    story.numberOfContributors = REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_NUM_CONTRIBUTORS]);
    story.numberOfViews = REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_NUM_VIEWS]);
    story.dateCreated = pfStory.createdAt;
    story.dateModified = pfStory.updatedAt;
    
    story.liked = [Story isStoryLiked:pfStory];
    story.favourite = [Story isStoryFavourited:pfStory];
    story.viewed = [Story isStoryViewed:pfStory];
    Scene *scene = [[Scene alloc] init];
    story.startingScene = scene;
    story.startingScene.sceneId = REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_STARTING_SCENE]);
    
    if ([[pfStory objectForKey:STORY_LOCATION_ENABLED] isEqualToNumber:[NSNumber numberWithBool:YES]])
    {
        story.isLocationEnabled = YES;
        double latitude = [REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_LATITUDE]) doubleValue];
        double longitude = [REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_LONGITUDE]) doubleValue];
        story.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        story.geocodedLocation = REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_GEOCODEDLOCATION]);
    } else 
    {
        story.isLocationEnabled = NO;
    }
    story.initialized = YES;

    story.imageURL = REPLACE_NULL_WITH_NIL([pfStory objectForKey:STORY_IMAGE_URL]);
    
    [ParseConnection resetPermission:story forPfStory:pfStory];
}

+ (void)loadScenesForStory:(Story *)story
{
    if (![[AFParseAPIClient sharedClient] isReachable]) {
        NSLog(@"%s No internet connection to load scenes for story: %@", __PRETTY_FUNCTION__, story.storyId);
        return;
    }
    PFQuery *query = [PFQuery queryWithClassName:@"Scene"];
    PFObject *pfScene = [query getObjectWithId:story.startingScene.sceneId];
    if (pfScene) {
        NSMutableArray *sceneArray = [[NSMutableArray alloc] initWithCapacity:[story.lengthOfStory unsignedIntValue]];
        [ParseConnection fillScene:story.startingScene withPfScene:pfScene forStory:story inArray:sceneArray];
        story.scenes = [sceneArray mutableCopy];
        [StoryDocuments saveStoryToDisk:story];
    } else {
        NSLog(@"%s Could not find a starting scene for story %@!!\n", __PRETTY_FUNCTION__, story);
    }
}

+ (void)fillScene:(Scene *)scene 
      withPfScene:(PFObject *)pfScene 
         forStory:(Story *)story 
          inArray:(NSMutableArray *)sceneArray;
{
    scene.text = REPLACE_NULL_WITH_NIL([pfScene objectForKey:SCENE_TEXT]);
    scene.sceneId = [pfScene objectId];
    scene.sceneNumberInStory = REPLACE_NULL_WITH_NIL([pfScene objectForKey:SCENE_NUMBER]);
    scene.story = story;
    scene.author = [User getUserForPfUser:[PFQuery getUserObjectWithId:REPLACE_NULL_WITH_NIL([pfScene objectForKey:SCENE_AUTHOR])]];
    scene.numberOfLikes = REPLACE_NULL_WITH_ZERO([pfScene objectForKey:SCENE_NUM_LIKES]);
    scene.numberOfContributors = REPLACE_NULL_WITH_ZERO([pfScene objectForKey:SCENE_NUM_CONTRIBUTORS]);
    scene.numberOfViews = REPLACE_NULL_WITH_ZERO([pfScene objectForKey:SCENE_NUM_VIEWS]);
    scene.dateCreated = pfScene.createdAt;
    scene.dateModified = pfScene.updatedAt;
    scene.liked = [Scene isSceneLiked:pfScene];
    scene.favourite = [Scene isSceneFavourited:pfScene];
    scene.viewed = [Scene isSceneViewed:pfScene];
    scene.initialized = YES;
    if (story.isLocationEnabled) {
        double latitude = [REPLACE_NULL_WITH_NIL([pfScene objectForKey:SCENE_LATITUDE]) doubleValue];
        double longitude = [REPLACE_NULL_WITH_NIL([pfScene objectForKey:SCENE_LONGITUDE]) doubleValue];
        scene.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        scene.geocodedLocation = REPLACE_NULL_WITH_NIL([pfScene objectForKey:SCENE_GEOCODEDLOCATION]);
    }
    
    scene.imageURL = REPLACE_NULL_WITH_NIL([pfScene objectForKey:SCENE_IMAGE_URL]);
    
    PFQuery *query = [PFQuery queryWithClassName:@"Scene"];
    NSString *pfPreviousSceneId = REPLACE_NULL_WITH_NIL([pfScene objectForKey:SCENE_PREVIOUSSCENE]);
    Scene *previousScene = nil;
    if (!scene.previousScene && pfPreviousSceneId)
    {
        PFObject *pfPreviousScene = [[query getObjectWithId:pfPreviousSceneId] fetchIfNeeded];
        previousScene = [[Scene alloc] init];
        scene.previousScene = previousScene;
        previousScene.nextScene = scene;
        
        [ParseConnection fillScene:previousScene 
                       withPfScene:pfPreviousScene
                          forStory:story 
                           inArray:sceneArray];
    }
    
    Scene *nextScene = nil;
    NSString *pfNextSceneId = REPLACE_NULL_WITH_NIL([pfScene objectForKey:SCENE_NEXTSCENE]);
    if (!scene.nextScene && pfNextSceneId)
    {
        PFObject *pfNextScene = [[query getObjectWithId:pfNextSceneId] fetchIfNeeded];
        nextScene = [[Scene alloc] init];
        scene.nextScene = nextScene;
        nextScene.previousScene = scene;
        
        [ParseConnection fillScene:nextScene
                       withPfScene:pfNextScene
                          forStory:story 
                           inArray:sceneArray];
    }
    [sceneArray insertObject:scene atIndex:0];
}

+ (void) resetPermissionsForStories:(NSMutableArray *)stories
{
    NSError *error = nil;
    for (Story *story in stories)
    {
        PFQuery *query = [PFQuery queryWithClassName:@"Story"];
        PFObject *pfStory = [query getObjectWithId:story.storyId error:&error];
        if (!pfStory)
        {
            NSLog(@"%s Error %@: Story does not exist", __PRETTY_FUNCTION__, error);
            return;
        }
        
        [ParseConnection resetPermission:story forPfStory:pfStory];
    }
}

+ (void) resetPermissionsForStory:(Story *)story
{
    NSError *error = nil;
    PFQuery *query = [PFQuery queryWithClassName:@"Story"];
    PFObject *pfStory = [query getObjectWithId:story.storyId error:&error];
    if (!pfStory)
    {
        NSLog(@"%s Error %@: Story does not exist", __PRETTY_FUNCTION__, error);
        return;
    }
    
    [ParseConnection resetPermission:story forPfStory:pfStory];
}

+ (void) resetPermission:(Story *)story forPfStory:(PFObject *)pfStory
{
    // Permission management
    // I am :
    story.isInvited = NO;
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"User Info"];
    if (userInfo) {
        if ([[pfStory objectForKey:STORY_PUBLIC_CONTRIBUTORS] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            // Public contributors
            story.canContribute = YES;
        } else {
            // Invited contributors
            NSArray *contributorsList = REPLACE_NULL_WITH_EMPTY_ARRAY([pfStory objectForKey:STORY_INVITED_TO_CONTRIBUTE]);
            story.invitedToContribute = contributorsList;
            NSDictionary *myAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [userInfo objectForKey:@"name"],
                                          @"name",
                                          [userInfo objectForKey:@"id"],
                                          @"id", nil];
            
            story.canContribute = NO;
            for (NSDictionary *contributor in contributorsList) {
                if ([contributor isEqualToDictionary:myAttributes]) {
                    story.canContribute = YES;
                    story.isInvited =YES;
                    break;
                }
            }
        }
        
        if ([[pfStory objectForKey:STORY_PUBLIC_VIEWERS] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            // Public viewers
            story.canView = YES;
        } else {
            // Invited viewers
            NSMutableArray *allAudience = [NSMutableArray arrayWithArray:REPLACE_NULL_WITH_EMPTY_ARRAY([pfStory objectForKey:STORY_INVITED_TO_VIEW])];
            [allAudience addObjectsFromArray:REPLACE_NULL_WITH_EMPTY_ARRAY([pfStory objectForKey:STORY_INVITED_TO_CONTRIBUTE])];
            NSArray *viewersList = [allAudience copy];
            story.invitedToView = viewersList;
            NSDictionary *myAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [userInfo objectForKey:@"name"], 
                                          @"name", 
                                          [userInfo objectForKey:@"id"], 
                                          @"id", nil];
            
            story.canView = NO;
            for (NSDictionary *viewer in viewersList) {
                if ([viewer isEqualToDictionary:myAttributes]) {
                    story.canView = YES;
                    story.isInvited = YES;
                    break;
                }
            }
        }
    }
    else {
        // Can't find user info!
        NSLog(@"%s Can't find user info", __PRETTY_FUNCTION__);
        story.canView = story.publicViewers;
        story.canContribute = NO;
    }
}

@end

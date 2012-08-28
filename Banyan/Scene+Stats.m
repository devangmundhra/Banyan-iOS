//
//  Scene+Stats.m
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene+Stats.h"
#import "Scene+Edit.h"
#import "User+Edit.h"
#import "AFParseAPIClient.h"
#import "Activity.h"

@implementation Scene (Stats)


+ (void) viewedScene:(Scene *)scene
{
    if (!scene) {
        NSLog(@"%s --ERROR-- No scene available!!", __PRETTY_FUNCTION__);
        return;
    }
    
    if (scene.viewed || !scene.initialized)
        return;
    
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;

    NSArray *alreadyViewedSceneId = currentUser.scenesViewed;
    NSMutableArray *mutArray = [NSMutableArray arrayWithCapacity:1];
    
    if (alreadyViewedSceneId)
    {
        if ([alreadyViewedSceneId containsObject:scene.sceneId])
            return;
        INCREMENT_SCENE_ATTRIBUTE_OPERATION(scene, SCENE_NUM_VIEWS, 1);
        [mutArray addObjectsFromArray:alreadyViewedSceneId];
        [mutArray addObject:scene.sceneId];
    } else {
        INCREMENT_SCENE_ATTRIBUTE_OPERATION(scene, SCENE_NUM_VIEWS, 1);
        [mutArray addObject:scene.sceneId];
    }
    
    currentUser.scenesViewed = [mutArray copy];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_SCENES_VIEWED];
    
    BNOperationObject *activityObj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeActivity tempId:nil storyId:nil];
    BNOperation *activityOp = [[BNOperation alloc] initWithObject:activityObj action:BNOperationActionCreate dependencies:nil];
    activityOp.action.context = [Activity activityWithType:kBNActivityTypeView
                                                  fromUser:currentUser.userId
                                                    toUser:currentUser.userId
                                                   sceneId:scene.sceneId storyId:nil];
    ADD_OPERATION_TO_QUEUE(activityOp);
                                 

    [User editUserNoOp:currentUser withAttributes:params];
    [User archiveCurrentUser];
    
    scene.viewed = YES;
    scene.numberOfViews = [NSNumber numberWithInt:([scene.numberOfViews intValue] + 1)];    
    return;
}

+ (BOOL) isSceneViewed:(PFObject *)pfScene
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return NO;
    
    NSArray *alreadyViewedSceneId = currentUser.scenesViewed;
    
    if ([alreadyViewedSceneId isEqual:[NSNull null]])
        return NO;
    
    if ([alreadyViewedSceneId containsObject:pfScene.objectId])
        return YES;
    
    return NO;
}

+ (void) toggleLikedScene:(Scene *)scene
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;
    
    NSArray *alreadyLikedSceneId = currentUser.scenesLiked;
    NSMutableArray *mutArray = nil;
    
    if (!alreadyLikedSceneId)
        mutArray = [NSMutableArray arrayWithCapacity:1];
    else 
        mutArray = [NSMutableArray arrayWithArray:alreadyLikedSceneId];
    
    if (scene.liked) {
        // unlike scene
        BNOperationObject *activityObj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeActivity tempId:nil storyId:nil];
        BNOperation *activityOp = [[BNOperation alloc] initWithObject:activityObj action:BNOperationActionDelete dependencies:nil];
        activityOp.action.context = [Activity activityWithType:kBNActivityTypeLike
                                                      fromUser:currentUser.userId
                                                        toUser:currentUser.userId
                                                       sceneId:scene.sceneId
                                                       storyId:nil];
        ADD_OPERATION_TO_QUEUE(activityOp);
        INCREMENT_SCENE_ATTRIBUTE_OPERATION(scene, SCENE_NUM_LIKES, -1);
        [mutArray removeObject:scene.sceneId];
    }
    else {
        // like scene
        BNOperationObject *activityObj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeActivity tempId:nil storyId:nil];
        BNOperation *activityOp = [[BNOperation alloc] initWithObject:activityObj action:BNOperationActionCreate dependencies:nil];
        activityOp.action.context = [Activity activityWithType:kBNActivityTypeLike
                                                      fromUser:currentUser.userId
                                                        toUser:currentUser.userId
                                                       sceneId:scene.sceneId
                                                       storyId:nil];
        ADD_OPERATION_TO_QUEUE(activityOp);
        
        INCREMENT_SCENE_ATTRIBUTE_OPERATION(scene, SCENE_NUM_LIKES, 1);
        [mutArray addObject:scene.sceneId];
    }
    currentUser.scenesLiked = [mutArray copy];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_SCENES_LIKED];
    [User editUserNoOp:currentUser withAttributes:params];
    [User archiveCurrentUser];
    
    if (scene.liked) {
        scene.liked = NO;
        scene.numberOfLikes = [NSNumber numberWithInt:([scene.numberOfLikes intValue] - 1)];
    } else {
        scene.liked = YES;
        scene.numberOfLikes = [NSNumber numberWithInt:([scene.numberOfLikes intValue] + 1)];
    }
}

+ (BOOL) isSceneLiked:(PFObject *)pfScene
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return NO;

    NSArray *alreadyLikedScene = currentUser.scenesLiked;
    
    if ([alreadyLikedScene isEqual:[NSNull null]])
        return NO;
        
    if ([alreadyLikedScene containsObject:pfScene.objectId])
        return YES;
     
    return NO;
}

+ (void) toggleFavouritedScene:(Scene *)scene
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;
    
    NSArray *alreadyFavouritedSceneId = currentUser.scenesFavourited;
    NSMutableArray *mutArray = nil;
    
    if ([alreadyFavouritedSceneId isEqual:[NSNull null]])
        mutArray = [NSMutableArray arrayWithCapacity:1];
    else 
        mutArray = [NSMutableArray arrayWithArray:alreadyFavouritedSceneId];
    
    if (scene.favourite) {
        // unfavourite scene
        BNOperationObject *activityObj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeActivity tempId:nil storyId:nil];
        BNOperation *activityOp = [[BNOperation alloc] initWithObject:activityObj action:BNOperationActionDelete dependencies:nil];
        activityOp.action.context = [Activity activityWithType:kBNActivityTypeFavourite
                                                      fromUser:currentUser.userId
                                                        toUser:currentUser.userId
                                                       sceneId:scene.sceneId
                                                       storyId:nil];
        ADD_OPERATION_TO_QUEUE(activityOp);
        
        [mutArray removeObject:scene.sceneId];
    }
    else {
        // favourite scene
        BNOperationObject *activityObj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeActivity tempId:nil storyId:nil];
        BNOperation *activityOp = [[BNOperation alloc] initWithObject:activityObj action:BNOperationActionCreate dependencies:nil];
        activityOp.action.context = [Activity activityWithType:kBNActivityTypeFavourite
                                                      fromUser:currentUser.userId
                                                        toUser:currentUser.userId
                                                       sceneId:scene.sceneId
                                                       storyId:nil];
        ADD_OPERATION_TO_QUEUE(activityOp);
        
        [mutArray addObject:scene.sceneId];
    }
    currentUser.scenesFavourited = [mutArray copy];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_SCENES_FAVOURITED];
    [User editUserNoOp:currentUser withAttributes:params];
    [User archiveCurrentUser];
    
    scene.favourite = !scene.favourite;
}

+ (BOOL) isSceneFavourited:(PFObject *)pfScene
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return NO;
    
    NSArray *alreadyFavouritedScene = currentUser.scenesFavourited;
    if ([alreadyFavouritedScene isEqual:[NSNull null]])
        return NO;
    
    if ([alreadyFavouritedScene containsObject:pfScene.objectId])
        return YES;

    return NO;
}

- (void) updateSceneStats
{
    [self updateViews];
    [self updateLikes];
    [self updateFavourites];
}

# pragma mark views
- (void) updateViews
{
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.sceneId, kBNActivitySceneKey, kBNActivityTypeView, kBNActivityTypeKey, nil];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    if (!jsonData) {
        NSLog(@"NSJSONSerialization failed %@", error);
    }
    
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *getViewNum = [NSMutableDictionary dictionaryWithObjectsAndKeys:json, @"where",
                                       [NSNumber numberWithInt:1], @"count",
                                       [NSNumber numberWithInt:0], @"limit", nil];
    
    [[AFParseAPIClient sharedClient] getPath:PARSE_API_CLASS_URL(kBNActivityClassKey)
                                  parameters:getViewNum
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSDictionary *numViewFields = responseObject;
                                         self.numberOfViews = [numViewFields objectForKey:@"count"];
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
}

# pragma mark likes
- (void) updateLikes
{
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.sceneId, kBNActivitySceneKey, kBNActivityTypeLike, kBNActivityTypeKey, nil];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    if (!jsonData) {
        NSLog(@"NSJSONSerialization failed %@", error);
    }
    
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *getLikes = [NSMutableDictionary dictionaryWithObjectsAndKeys:json, @"where",
                                       [NSNumber numberWithInt:1], @"count",
                                       [NSNumber numberWithInt:0], @"limit", nil];
    
    [[AFParseAPIClient sharedClient] getPath:PARSE_API_CLASS_URL(kBNActivityClassKey)
                                  parameters:getLikes
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSDictionary *numViewFields = responseObject;
                                         self.numberOfLikes = [numViewFields objectForKey:@"count"];
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
}

# pragma mark favourites
- (void) updateFavourites
{

}

@end

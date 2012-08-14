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
#import "ParseAPIEngine.h"

@implementation Scene (Stats)


+ (void) viewedScene:(Scene *)scene
{
    if (!scene) {
        NSLog(@"%s --ERROR-- No scene available!!", __PRETTY_FUNCTION__);
        return;
    }
    
    if (scene.viewed)
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

    [User editUserNoOp:currentUser withAttributes:params];
    
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
        INCREMENT_SCENE_ATTRIBUTE_OPERATION(scene, SCENE_NUM_LIKES, -1);
        [mutArray removeObject:scene.sceneId];
    }
    else {
        // like scene
        INCREMENT_SCENE_ATTRIBUTE_OPERATION(scene, SCENE_NUM_LIKES, 1);
        [mutArray addObject:scene.sceneId];
    }
    currentUser.scenesLiked = [mutArray copy];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_SCENES_LIKED];
    [User editUserNoOp:currentUser withAttributes:params];

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
        [mutArray removeObject:scene.sceneId];
    }
    else {
        // favourite scene
        [mutArray addObject:scene.sceneId];
    }
    currentUser.scenesFavourited = [mutArray copy];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_SCENES_FAVOURITED];
    [User editUserNoOp:currentUser withAttributes:params];
    
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
@end

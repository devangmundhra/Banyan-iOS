//
//  Scene+Stats.m
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene+Stats.h"
#import "Scene_Defines.h"
#import "User_Defines.h"
#import "Scene+Edit.h"

@implementation Scene (Stats)


+ (void) viewedScene:(Scene *)scene
{
    if (!scene) {
        NSLog(@"%s --ERROR-- No scene available!!", __PRETTY_FUNCTION__);
        return;
    }
    
    if (scene.viewed)
        return;
    
    if (!scene.sceneId) {
        NSLog(@"%s Remember to correct this later. Proper counting for views", __PRETTY_FUNCTION__);
        return;
    }
    
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return;

    if (!scene.initialized) {
        NSLog(@"%s Scene not yet initialized", __PRETTY_FUNCTION__);
        return;
    }

    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];
    NSArray *alreadyViewedSceneId = [user objectForKey:USER_SCENES_VIEWED];
    NSMutableArray *mutArray = [NSMutableArray arrayWithCapacity:1];
    
    if (alreadyViewedSceneId)
    {
        if ([alreadyViewedSceneId containsObject:scene.sceneId])
            return;
        
        [scene incrementSceneAttribute:SCENE_NUM_VIEWS byAmount:[NSNumber numberWithInt:1]];
        [mutArray addObjectsFromArray:alreadyViewedSceneId];
        [mutArray addObject:scene.sceneId];
    } else {
        [scene incrementSceneAttribute:SCENE_NUM_VIEWS byAmount:[NSNumber numberWithInt:1]];
        [mutArray addObject:scene.sceneId];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_SCENES_VIEWED];
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_USER_URL(currentUser.objectId)
                                                                       params:params
                                                                   httpMethod:@"PUT" 
                                                                          ssl:YES];
    [op addHeaders:[NSDictionary dictionaryWithObject:currentUser.sessionToken forKey:@"X-Parse-Session-Token"]];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSDictionary *response = [completedOperation responseJSON];
        NSLog(@"Got response for updating user at %@", [response objectForKey:@"updatedAt"]);
    }  
             onError:PARSE_ERROR_BLOCK()];
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
    
    scene.viewed = YES;
    scene.numberOfViews = [NSNumber numberWithInt:([scene.numberOfViews intValue] + 1)];    
    return;
}

+ (BOOL) isSceneViewed:(PFObject *)pfScene
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return NO;
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];
    
    NSArray *alreadyViewedSceneId = [user objectForKey:USER_SCENES_VIEWED];
    
    if ([alreadyViewedSceneId isEqual:[NSNull null]])
        return NO;
    
    if ([alreadyViewedSceneId containsObject:pfScene.objectId])
        return YES;
    
    return NO;
}

+ (void) toggleLikedScene:(Scene *)scene
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return;
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];
    
    if (!scene.sceneId) {
        NSLog(@"%s Remember to correct this later. Proper like count for views", __PRETTY_FUNCTION__);
        return;
    }
    
    if (!scene.initialized) {
        NSLog(@"%s Scene not yet initialized", __PRETTY_FUNCTION__);
        return;
    }
    
    NSArray *alreadyLikedSceneId = [user objectForKey:USER_SCENES_LIKED];
    NSMutableArray *mutArray = nil;
    
    if ([alreadyLikedSceneId isEqual:[NSNull null]])
        mutArray = [NSMutableArray arrayWithCapacity:1];
    else 
        mutArray = [NSMutableArray arrayWithArray:alreadyLikedSceneId];
    
    if (scene.liked) {
        // unlike scene
        [scene incrementSceneAttribute:SCENE_NUM_LIKES byAmount:[NSNumber numberWithInt:-1]];
        [mutArray removeObject:scene.sceneId];
    }
    else {
        // like scene
        [scene incrementSceneAttribute:SCENE_NUM_LIKES byAmount:[NSNumber numberWithInt:1]];
        [mutArray addObject:scene.sceneId];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_SCENES_LIKED];
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_USER_URL(currentUser.objectId)
                                                                       params:params
                                                                   httpMethod:@"PUT" 
                                                                          ssl:YES];
    [op addHeaders:[NSDictionary dictionaryWithObject:currentUser.sessionToken forKey:@"X-Parse-Session-Token"]];
    
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSDictionary *response = [completedOperation responseJSON];
        NSLog(@"Got response for updating user at %@", [response objectForKey:@"updatedAt"]);
    }  
             onError:PARSE_ERROR_BLOCK()];
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];

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
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return NO;
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];

    NSArray *alreadyLikedScene = [user objectForKey:USER_SCENES_LIKED];
    
    if ([alreadyLikedScene isEqual:[NSNull null]])
        return NO;
        
    if ([alreadyLikedScene containsObject:pfScene.objectId])
        return YES;
     
    return NO;
}

+ (void) toggleFavouritedScene:(Scene *)scene
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return;
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];
    
    if (!scene.sceneId) {
        NSLog(@"%s Remember to correct this later. Proper favourite for views", __PRETTY_FUNCTION__);
        return;
    }
    
    if (!scene.initialized) {
        NSLog(@"%s Scene not yet initialized", __PRETTY_FUNCTION__);
        return;
    }
    
    NSArray *alreadyFavouritedSceneId = [user objectForKey:USER_SCENES_FAVOURITES];
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
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_SCENES_FAVOURITES];
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_USER_URL(currentUser.objectId)
                                                                       params:params
                                                                   httpMethod:@"PUT" 
                                                                          ssl:YES];
    [op addHeaders:[NSDictionary dictionaryWithObject:currentUser.sessionToken forKey:@"X-Parse-Session-Token"]];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSDictionary *response = [completedOperation responseJSON];
        NSLog(@"Got response for updating user at %@", [response objectForKey:@"updatedAt"]);
    }  
             onError:PARSE_ERROR_BLOCK()];
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
    
    scene.favourite = !scene.favourite;
}

+ (BOOL) isSceneFavourited:(PFObject *)pfScene
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return NO;
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];
    
    NSArray *alreadyFavouritedScene = [user objectForKey:USER_SCENES_FAVOURITES];
    if ([alreadyFavouritedScene isEqual:[NSNull null]])
        return NO;
    
    if ([alreadyFavouritedScene containsObject:pfScene.objectId])
        return YES;

    return NO;
}
@end

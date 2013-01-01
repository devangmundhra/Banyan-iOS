//
//  Scene+Stats.m
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece+Stats.h"
#import "Piece+Edit.h"
#import "User+Edit.h"
#import "AFParseAPIClient.h"
#import "Activity+Create.h"

@implementation Piece (Stats)


+ (void) viewedPiece:(Piece *)scene
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
    
    Activity *activity = [Activity activityWithType:kBNActivityTypeView
                                           fromUser:currentUser.userId
                                             toUser:currentUser.userId
                                            sceneId:scene.pieceId storyId:nil];
    [Activity createActivity:activity];
    
    scene.viewed = YES;
    scene.numberOfViews = [NSNumber numberWithInt:([scene.numberOfViews intValue] + 1)];    
    return;
}

+ (void) toggleLikedPiece:(Piece *)scene
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;
    
    NSMutableArray *likers = [scene.likers mutableCopy];
    Activity *activity = nil;
    if (scene.liked) {
        // unlike scene
        activity = [Activity activityWithType:kBNActivityTypeUnlike
                                     fromUser:currentUser.userId
                                       toUser:currentUser.userId
                                      sceneId:scene.pieceId
                                      storyId:nil];
        [likers removeObject:currentUser.userId];
        
        scene.liked = NO;
        scene.numberOfLikes = [NSNumber numberWithInt:([scene.numberOfLikes intValue] - 1)];
    }
    else {
        // like scene
        activity = [Activity activityWithType:kBNActivityTypeLike
                                     fromUser:currentUser.userId
                                       toUser:currentUser.userId
                                      sceneId:scene.pieceId
                                      storyId:nil];
        [likers addObject:currentUser.userId];
        
        scene.liked = YES;
        scene.numberOfLikes = [NSNumber numberWithInt:([scene.numberOfLikes intValue] + 1)];
    }
    [Activity createActivity:activity];
    scene.likers = likers;
}

+ (void) toggleFavouritedPiece:(Piece *)scene
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;
    Activity *activity = nil;
    if (scene.favourite) {
        // unfavourite scene
        activity = [Activity activityWithType:kBNActivityTypeUnfavourite
                                     fromUser:currentUser.userId
                                       toUser:currentUser.userId
                                      sceneId:scene.pieceId
                                      storyId:nil];
    }
    else {
        // favourite scene
        activity = [Activity activityWithType:kBNActivityTypeFavourite
                                    fromUser:currentUser.userId
                                      toUser:currentUser.userId
                                     sceneId:scene.pieceId
                                     storyId:nil];
    }
    [Activity createActivity:activity];    
    scene.favourite = !scene.favourite;
}

- (void) updatePieceStats
{
    [self updateViews];
    [self updateLikes];
    [self updateFavourites];
}

# pragma mark views
- (void) updateViews
{
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.pieceId, kBNActivitySceneKey, kBNActivityTypeView, kBNActivityTypeKey, nil];
    
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
    
    User *currentUser = [User currentUser];
    if (currentUser) {
        [jsonDictionary setObject:currentUser.userId forKey:kBNActivityFromUserKey];
        jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
        if (!jsonData) {
            NSLog(@"NSJSONSerialization failed %@", error);
        }
        json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        getViewNum = [NSMutableDictionary dictionaryWithObjectsAndKeys:json, @"where",
                      [NSNumber numberWithInt:1], @"count",
                      [NSNumber numberWithInt:0], @"limit", nil];
        
        [[AFParseAPIClient sharedClient] getPath:PARSE_API_CLASS_URL(kBNActivityClassKey)
                                      parameters:getViewNum
                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             NSDictionary *numViewFields = responseObject;
                                             NSNumber *views = [numViewFields objectForKey:@"count"];
                                             if ([views integerValue] > 0) {
                                                 self.viewed = YES;
                                             }
                                         }
                                         failure:AF_PARSE_ERROR_BLOCK()];
    }
}

# pragma mark likes
- (void) updateLikes
{
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.pieceId, kBNActivitySceneKey, kBNActivityTypeLike, kBNActivityTypeKey, nil];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    if (!jsonData) {
        NSLog(@"NSJSONSerialization failed %@", error);
    }
    
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *getLikes = [NSMutableDictionary dictionaryWithObjectsAndKeys:json, @"where",
                                       [NSNumber numberWithInt:1], @"count", nil];
    
    [[AFParseAPIClient sharedClient] getPath:PARSE_API_CLASS_URL(kBNActivityClassKey)
                                  parameters:getLikes
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSDictionary *likerFields = responseObject;
                                         self.numberOfLikes = [likerFields objectForKey:@"count"];
                                         NSMutableArray *likers = [NSMutableArray arrayWithCapacity:[self.numberOfLikes integerValue]];
                                         for (NSDictionary *liker in [likerFields objectForKey:@"results"]) {
                                             [likers addObject:[liker objectForKey:kBNActivityFromUserKey]];
                                         }
                                         self.likers = [likers copy];
                                         User *currentUser = [User currentUser];
                                         if (currentUser) {
                                             if ([self.likers containsObject:currentUser.userId]) {
                                                 self.liked = YES;
                                             }
                                         }
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
}

# pragma mark favourites
- (void) updateFavourites
{
    User *currentUser = [User currentUser];
    if (!currentUser) {
        return;
    }
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.pieceId, kBNActivitySceneKey, kBNActivityTypeFavourite, kBNActivityTypeKey, currentUser.userId, kBNActivityFromUserKey, nil];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    if (!jsonData) {
        NSLog(@"NSJSONSerialization failed %@", error);
    }
    
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *getFavs = [NSMutableDictionary dictionaryWithObjectsAndKeys:json, @"where",
                                     [NSNumber numberWithInt:1], @"count",
                                     [NSNumber numberWithInt:0], @"limit", nil];
    
    [[AFParseAPIClient sharedClient] getPath:PARSE_API_CLASS_URL(kBNActivityClassKey)
                                  parameters:getFavs
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSDictionary *numFavFields = responseObject;
                                         NSNumber *favs = [numFavFields objectForKey:@"count"];
                                         if ([favs integerValue] > 0) {
                                             self.favourite = YES;
                                         }
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
}

@end

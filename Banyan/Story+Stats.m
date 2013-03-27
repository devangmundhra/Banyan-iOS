//
//  Story+Stats.m
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Stats.h"
#import "User+Edit.h"
#import "Story+Edit.h"
#import "AFParseAPIClient.h"
#import "Activity+Create.h"

@implementation Story (Stats)


+ (void) viewedStory:(Story *)story
{
    if (story.viewed)
        return;
    
    if (!story.id) {
        NSLog(@"%s Remember to correct this later. Proper counting for views", __PRETTY_FUNCTION__);
        return;
    }
    
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;

    Activity *activity = [Activity activityWithType:kBNActivityTypeView
                                           fromUser:currentUser.userId
                                             toUser:currentUser.userId
                                            pieceId:nil
                                            storyId:story.id];
    [Activity createActivity:activity];
    
    story.viewed = [NSNumber numberWithBool:YES];
    story.numberOfViews = [NSNumber numberWithInt:([story.numberOfViews intValue] + 1)];
}

+ (void) toggleLikedStory:(Story *)story
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;
    
    NSMutableArray *likers = [story.likers mutableCopy];
    
    Activity *activity = nil;
    if (story.liked) {
        // unlike story
        story.liked = [NSNumber numberWithBool:NO];
        story.numberOfLikes = [NSNumber numberWithInt:([story.numberOfLikes intValue] - 1)];
        activity = [Activity activityWithType:kBNActivityTypeUnlike
                                     fromUser:currentUser.userId
                                       toUser:currentUser.userId
                                      pieceId:nil
                                      storyId:story.id];
        [likers removeObject:currentUser.userId];
    }
    else {
        // like story
        story.liked = [NSNumber numberWithBool:YES];
        story.numberOfLikes = [NSNumber numberWithInt:([story.numberOfLikes intValue] + 1)];
        activity = [Activity activityWithType:kBNActivityTypeLike
                                     fromUser:currentUser.userId
                                       toUser:currentUser.userId
                                      pieceId:nil
                                      storyId:story.id];

        [likers addObject:currentUser.userId];
    }
    [Activity createActivity:activity];
    story.likers = likers;
}

+ (void) toggleFavouritedStory:(Story *)story
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;
    
    Activity *activity = nil;
    if (story.favourite) {
        // unfavourite story
        activity = [Activity activityWithType:kBNActivityTypeUnfavourite
                                     fromUser:currentUser.userId
                                       toUser:currentUser.userId
                                      pieceId:nil
                                      storyId:story.id];
        story.favourite = [NSNumber numberWithBool:NO];
    }
    else {
        // favourite story
        activity = [Activity activityWithType:kBNActivityTypeFavourite
                                     fromUser:currentUser.userId
                                       toUser:currentUser.userId
                                      pieceId:nil
                                      storyId:story.id];
        story.favourite = [NSNumber numberWithBool:YES];
    }
    [Activity createActivity:activity];
}

- (void) updateStoryStats
{
    [self updateViews];
    [self updateLikes];
    [self updateFavourites];
}

# pragma mark views
- (void) updateViews
{
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.id, kBNActivityStoryKey, kBNActivityTypeView, kBNActivityTypeKey, nil];
    
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
                                                 self.viewed = [NSNumber numberWithBool:YES];
                                             }
                                         }
                                         failure:AF_PARSE_ERROR_BLOCK()];
    }
}

# pragma mark likes
- (void) updateLikes
{
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.id, kBNActivityStoryKey, kBNActivityTypeLike, kBNActivityTypeKey, nil];
    
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
                                                 self.liked = [NSNumber numberWithBool:YES];
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
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.id, kBNActivityStoryKey, kBNActivityTypeFavourite, kBNActivityTypeKey, currentUser.userId, kBNActivityFromUserKey, nil];
    
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
                                             self.favourite = [NSNumber numberWithBool:YES];
                                         }
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
}

@end


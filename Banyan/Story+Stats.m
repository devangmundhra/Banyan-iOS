//
//  Story+Stats.m
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Stats.h"
#import "Story+Edit.h"
#import "AFParseAPIClient.h"
#import "Activity+Create.h"
#import "Statistics.h"

@implementation Story (Stats)


+ (void) viewedStory:(Story *)story
{
    if (story.statistics.viewed)
        return;
    
    if (!story.bnObjectId) {
        NSLog(@"%s Remember to correct this later. Proper counting for views", __PRETTY_FUNCTION__);
        return;
    }
    
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return;

    Activity *activity = [Activity activityWithType:kBNActivityTypeView
                                           fromUser:currentUser.objectId
                                             toUser:currentUser.objectId
                                            pieceId:nil
                                            storyId:story.bnObjectId];
    [Activity createActivity:activity];
    
    story.statistics.viewed = [NSNumber numberWithBool:YES];
    story.statistics.numberOfViews = [NSNumber numberWithInt:([story.statistics.numberOfViews intValue] + 1)];
}

+ (void) toggleLikedStory:(Story *)story
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return;
    
    NSMutableSet *likers = [story.statistics.likers mutableCopy];
    
    Activity *activity = nil;
    if (story.statistics.liked) {
        // unlike story
        story.statistics.liked = [NSNumber numberWithBool:NO];
        story.statistics.numberOfLikes = [NSNumber numberWithInt:([story.statistics.numberOfLikes intValue] - 1)];
        activity = [Activity activityWithType:kBNActivityTypeUnlike
                                     fromUser:currentUser.objectId
                                       toUser:currentUser.objectId
                                      pieceId:nil
                                      storyId:story.bnObjectId];
        [likers removeObject:currentUser.objectId];
    }
    else {
        // like story
        story.statistics.liked = [NSNumber numberWithBool:YES];
        story.statistics.numberOfLikes = [NSNumber numberWithInt:([story.statistics.numberOfLikes intValue] + 1)];
        activity = [Activity activityWithType:kBNActivityTypeLike
                                     fromUser:currentUser.objectId
                                       toUser:currentUser.objectId
                                      pieceId:nil
                                      storyId:story.bnObjectId];

        [likers addObject:currentUser.objectId];
    }
    [Activity createActivity:activity];
    story.statistics.likers = likers;
}

+ (void) toggleFavouritedStory:(Story *)story
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return;
    
    Activity *activity = nil;
    if (story.statistics.favourite) {
        // unfavourite story
        activity = [Activity activityWithType:kBNActivityTypeUnfavourite
                                     fromUser:currentUser.objectId
                                       toUser:currentUser.objectId
                                      pieceId:nil
                                      storyId:story.bnObjectId];
        story.statistics.favourite = [NSNumber numberWithBool:NO];
    }
    else {
        // favourite story
        activity = [Activity activityWithType:kBNActivityTypeFavourite
                                     fromUser:currentUser.objectId
                                       toUser:currentUser.objectId
                                      pieceId:nil
                                      storyId:story.bnObjectId];
        story.statistics.favourite = [NSNumber numberWithBool:YES];
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
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.bnObjectId, kBNActivityStoryKey, kBNActivityTypeView, kBNActivityTypeKey, nil];
    
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
                                         self.statistics.numberOfViews = [numViewFields objectForKey:@"count"];
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
    
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [jsonDictionary setObject:currentUser.objectId forKey:kBNActivityFromUserKey];
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
                                                 self.statistics.viewed = [NSNumber numberWithBool:YES];
                                             }
                                         }
                                         failure:AF_PARSE_ERROR_BLOCK()];
    }
}

# pragma mark likes
- (void) updateLikes
{
    NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:self.bnObjectId, kBNActivityStoryKey, kBNActivityTypeLike, kBNActivityTypeKey, nil];
    
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
                                         self.statistics.numberOfLikes = [likerFields objectForKey:@"count"];
                                         NSMutableArray *likers = [NSMutableArray arrayWithCapacity:[self.statistics.numberOfLikes integerValue]];
                                         for (NSDictionary *liker in [likerFields objectForKey:@"results"]) {
                                             [likers addObject:[liker objectForKey:kBNActivityFromUserKey]];
                                         }
                                         self.statistics.likers = [likers copy];
                                         PFUser *currentUser = [PFUser currentUser];
                                         if (currentUser) {
                                             if ([self.statistics.likers containsObject:currentUser.objectId]) {
                                                 self.statistics.liked = [NSNumber numberWithBool:YES];
                                             }
                                         }
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
}

# pragma mark favourites
- (void) updateFavourites
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser) {
        return;
    }
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.bnObjectId, kBNActivityStoryKey, kBNActivityTypeFavourite, kBNActivityTypeKey, currentUser.objectId, kBNActivityFromUserKey, nil];
    
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
                                             self.statistics.favourite = [NSNumber numberWithBool:YES];
                                         }
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
}

@end


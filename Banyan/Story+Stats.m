//
//  Story+Stats.m
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Stats.h"
#import "Story_Defines.h"
#import "User_Defines.h"
#import "StoryDocuments.h"
#import "Story+Edit.h"

@implementation Story (Stats)


+ (void) viewedStory:(Story *)story
{
    if (story.viewed)
        return;
    
    if (!story.storyId) {
        NSLog(@"%s Remember to correct this later. Proper counting for views", __PRETTY_FUNCTION__);
        return;
    }
    
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return;
    
    if (!story.initialized) {
        NSLog(@"%s Story not yet initialized", __PRETTY_FUNCTION__);
        return;
    }
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];
    
    NSArray *alreadyViewedStoryId = [user objectForKey:USER_SCENES_VIEWED];
    NSMutableArray *mutArray = [NSMutableArray arrayWithCapacity:1];
    
    if (alreadyViewedStoryId)
    {
        if ([alreadyViewedStoryId containsObject:story.storyId])
            return;
        
        [story incrementStoryAttribute:STORY_NUM_VIEWS byAmount:[NSNumber numberWithInt:1]];
        [mutArray addObjectsFromArray:alreadyViewedStoryId];
        [mutArray addObject:story.storyId];
    } else {
        [story incrementStoryAttribute:STORY_NUM_VIEWS byAmount:[NSNumber numberWithInt:1]];
        [mutArray addObject:story.storyId];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_STORIES_VIEWED];
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

    story.viewed = YES;
    story.numberOfViews = [NSNumber numberWithInt:([story.numberOfViews intValue] + 1)];
}

+ (BOOL) isStoryViewed:(PFObject *)pfStory
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return NO;
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];

    NSArray *alreadyViewedStoriesId = [user objectForKey:USER_STORIES_VIEWED];
    
    if ([alreadyViewedStoriesId isEqual:[NSNull null]])
        return NO;
    
    if ([alreadyViewedStoriesId containsObject:pfStory.objectId])
        return YES;
    
    return NO;
}

+ (void) toggleLikedStory:(Story *)story
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return;
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];

    if (!story.storyId) {
        NSLog(@"%s Remember to correct this later. Proper likes for views", __PRETTY_FUNCTION__);
        return;
    }
    if (!story.initialized) {
        NSLog(@"%s Story not yet initialized", __PRETTY_FUNCTION__);
        return;
    }
    
    NSArray *alreadyLikedStoryId = [user objectForKey:USER_STORIES_LIKED];
    NSMutableArray *mutArray = nil;
    
    if ([alreadyLikedStoryId isEqual:[NSNull null]])
        mutArray = [NSMutableArray arrayWithCapacity:1];
    else 
        mutArray = [NSMutableArray arrayWithArray:alreadyLikedStoryId];
    
    if (story.liked) {
        // unlike story
        [story incrementStoryAttribute:STORY_NUM_LIKES byAmount:[NSNumber numberWithInt:-1]];
        [mutArray removeObject:story.storyId];
        
        story.liked = NO;
        story.numberOfLikes = [NSNumber numberWithInt:([story.numberOfLikes intValue] - 1)];
    }
    else {
        // like story
        [story incrementStoryAttribute:STORY_NUM_LIKES byAmount:[NSNumber numberWithInt:1]];
        [mutArray addObject:story.storyId];
        
        story.liked = YES;
        story.numberOfLikes = [NSNumber numberWithInt:([story.numberOfLikes intValue] + 1)];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_STORIES_LIKED];
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
}

+ (BOOL) isStoryLiked:(PFObject *)pfStory
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return NO;
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];

    NSArray *alreadyLikedStoriesId = [user objectForKey:USER_STORIES_LIKED];
    
    if ([alreadyLikedStoriesId isEqual:[NSNull null]])
        return NO;
    
    if ([alreadyLikedStoriesId containsObject:pfStory.objectId])
        return YES;
    
    return NO;
}

+ (void) toggleFavouritedStory:(Story *)story
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return;
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];

    if (!story.storyId) {
        NSLog(@"%s Remember to correct this later. Proper favourites for views", __PRETTY_FUNCTION__);
        return;
    }
    
    if (!story.initialized) {
        NSLog(@"%s Story not yet initialized", __PRETTY_FUNCTION__);
        return;
    }
    
    NSArray *alreadyFavouritedStoryId = [user objectForKey:USER_STORIES_FAVOURITES];
    NSMutableArray *mutArray = nil;
    
    if ([alreadyFavouritedStoryId isEqual:[NSNull null]])
        mutArray = [NSMutableArray arrayWithCapacity:1];
    else 
        mutArray = [NSMutableArray arrayWithArray:alreadyFavouritedStoryId];
    
    if (story.favourite) {
        // unfavourite story
        [mutArray removeObject:story.storyId];
    }
    else {
        // favourite story
        [mutArray addObject:story.storyId];
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_STORIES_FAVOURITES];
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
    
    story.favourite = !story.favourite;
}

+ (BOOL) isStoryFavourited:(PFObject *)pfStory
{
    PFUser *currentUser = [PFUser currentUser];
    if (!currentUser)
        return NO;
    PFUser *user = [PFQuery getUserObjectWithId:currentUser.objectId];

    NSArray *alreadyFavouritedStoriesId = [user objectForKey:USER_STORIES_FAVOURITES];
    if ([alreadyFavouritedStoriesId isEqual:[NSNull null]])
        return NO;
    
    if ([alreadyFavouritedStoriesId containsObject:pfStory.objectId])
        return YES;
    
    return NO;
}
@end


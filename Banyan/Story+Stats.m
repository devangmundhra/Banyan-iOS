//
//  Story+Stats.m
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Stats.h"
#import "User+Edit.h"
#import "StoryDocuments.h"
#import "Story+Edit.h"
#import "ParseAPIEngine.h"

@implementation Story (Stats)


+ (void) viewedStory:(Story *)story
{
    if (story.viewed)
        return;
    
    if (!story.storyId) {
        NSLog(@"%s Remember to correct this later. Proper counting for views", __PRETTY_FUNCTION__);
        return;
    }
    
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;
        
    NSArray *alreadyViewedStoryId = currentUser.storiesViewed;
    NSMutableArray *mutArray = [NSMutableArray arrayWithCapacity:1];
    
    if (alreadyViewedStoryId)
    {
        if ([alreadyViewedStoryId containsObject:story.storyId])
            return;
        INCREMENT_STORY_ATTRIBUTE_OPERATION(story, STORY_NUM_VIEWS, 1);
        [mutArray addObjectsFromArray:alreadyViewedStoryId];
        [mutArray addObject:story.storyId];
    } else {
        INCREMENT_STORY_ATTRIBUTE_OPERATION(story, STORY_NUM_VIEWS, 1);
        [mutArray addObject:story.storyId];
    }
    currentUser.storiesViewed = [mutArray copy];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_STORIES_VIEWED];
    [User editUserNoOp:currentUser withAttributes:params];

    story.viewed = YES;
    story.numberOfViews = [NSNumber numberWithInt:([story.numberOfViews intValue] + 1)];
}

+ (BOOL) isStoryViewed:(PFObject *)pfStory
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return NO;

    NSArray *alreadyViewedStoriesId = currentUser.storiesViewed;
    
    if ([alreadyViewedStoriesId isEqual:[NSNull null]])
        return NO;
    
    if ([alreadyViewedStoriesId containsObject:pfStory.objectId])
        return YES;
    
    return NO;
}

+ (void) toggleLikedStory:(Story *)story
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;
    
    NSArray *alreadyLikedStoryId = currentUser.storiesLiked;
    NSMutableArray *mutArray = nil;
    
    if ([alreadyLikedStoryId isEqual:[NSNull null]])
        mutArray = [NSMutableArray arrayWithCapacity:1];
    else 
        mutArray = [NSMutableArray arrayWithArray:alreadyLikedStoryId];
    
    if (story.liked) {
        // unlike story
        INCREMENT_STORY_ATTRIBUTE_OPERATION(story, STORY_NUM_LIKES, -1);
        [mutArray removeObject:story.storyId];
        
        story.liked = NO;
        story.numberOfLikes = [NSNumber numberWithInt:([story.numberOfLikes intValue] - 1)];
    }
    else {
        // like story
        INCREMENT_STORY_ATTRIBUTE_OPERATION(story, STORY_NUM_LIKES, 1);
        [mutArray addObject:story.storyId];
        
        story.liked = YES;
        story.numberOfLikes = [NSNumber numberWithInt:([story.numberOfLikes intValue] + 1)];
    }
    currentUser.storiesLiked = [mutArray copy];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_STORIES_LIKED];
    [User editUserNoOp:currentUser withAttributes:params];
}

+ (BOOL) isStoryLiked:(PFObject *)pfStory
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return NO;

    NSArray *alreadyLikedStoriesId = currentUser.storiesLiked;
    
    if ([alreadyLikedStoriesId isEqual:[NSNull null]])
        return NO;
    
    if ([alreadyLikedStoriesId containsObject:pfStory.objectId])
        return YES;
    
    return NO;
}

+ (void) toggleFavouritedStory:(Story *)story
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return;
    
    NSArray *alreadyFavouritedStoryId = currentUser.storiesFavourited;
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
    currentUser.storiesFavourited = [mutArray copy];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:[mutArray copy] forKey:USER_STORIES_FAVOURITED];
    [User editUserNoOp:currentUser withAttributes:params];
    
    story.favourite = !story.favourite;
}

+ (BOOL) isStoryFavourited:(PFObject *)pfStory
{
    User *currentUser = [User currentUser];
    if (!currentUser)
        return NO;

    NSArray *alreadyFavouritedStoriesId = currentUser.storiesFavourited;
    if ([alreadyFavouritedStoriesId isEqual:[NSNull null]])
        return NO;
    
    if ([alreadyFavouritedStoriesId containsObject:pfStory.objectId])
        return YES;
    
    return NO;
}
@end


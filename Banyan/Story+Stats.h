//
//  Story+Stats.h
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import <Parse/Parse.h>

@interface Story (Stats)

+ (void) viewedStory:(Story *)story;

+ (void) toggleLikedStory:(Story *)story;

+ (BOOL) isStoryLiked:(PFObject *)pfStory;

+ (void) toggleFavouritedStory:(Story *)story;

+ (BOOL) isStoryFavourited:(PFObject *)pfStory;

+ (BOOL) isStoryViewed:(PFObject *)pfStory;

@end

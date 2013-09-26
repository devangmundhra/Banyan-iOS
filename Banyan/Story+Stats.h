//
//  Story+Stats.h
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"

// PUT_API_TODO
@interface Story (Stats)

+ (void) viewedStory:(Story *)story;

+ (void) toggleLikedStory:(Story *)story;

+ (void) toggleFavouritedStory:(Story *)story;

@end

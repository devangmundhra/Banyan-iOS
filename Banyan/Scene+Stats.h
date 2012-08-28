//
//  Scene+Stats.h
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene.h"
#import <Parse/Parse.h>

// PUT_API_TODO

@interface Scene (Stats)

+ (void) viewedScene:(Scene *)scene;

+ (void) toggleLikedScene:(Scene *)scene;

+ (BOOL) isSceneLiked:(PFObject *)pfScene;

+ (void) toggleFavouritedScene:(Scene *)scene;

+ (BOOL) isSceneFavourited:(PFObject *)pfScene;

+ (BOOL) isSceneViewed:(PFObject *)pfScene;

- (void) updateSceneStats;

@end

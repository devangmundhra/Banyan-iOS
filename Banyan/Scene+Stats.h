//
//  Scene+Stats.h
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece.h"
#import <Parse/Parse.h>

// PUT_API_TODO

@interface Piece (Stats)

+ (void) viewedScene:(Piece *)scene;

+ (void) toggleLikedScene:(Piece *)scene;

+ (void) toggleFavouritedScene:(Piece *)scene;

- (void) updateSceneStats;

@end

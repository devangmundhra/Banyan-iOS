//
//  Scene+Stats.h
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece.h"

// PUT_API_TODO

@interface Piece (Stats)

+ (void) viewedPiece:(Piece *)scene;

+ (void) toggleLikedPiece:(Piece *)scene;

+ (void) toggleFavouritedPiece:(Piece *)scene;

//- (void) updatePieceStats;

@end

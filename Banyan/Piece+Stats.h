//
//  Scene+Stats.h
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "Piece.h"

// PUT_API_TODO

@interface Piece (Stats)

+ (void) viewedPiece:(Piece *)piece;

+ (void) toggleLikedPiece:(Piece *)piece;

+ (void) toggleFavouritedPiece:(Piece *)piece;

@end

//
//  Piece+Create.h
//  Storied
//
//  Created by Devang Mundhra on 3/11/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "Piece.h"

@interface Piece (Create)
+ (void)createNewPiece:(Piece *)piece;

+ (Piece *) newPieceDraftForStory:(Story *)story;

@end

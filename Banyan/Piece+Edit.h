//
//  Scene+Edit.h
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece.h"
#import <Parse/Parse.h>
#import "Piece_Defines.h"

@interface Piece (Edit)
+ (void) editPiece:(Piece *)piece;
@end

//
//  Scene+Create.h
//  Storied
//
//  Created by Devang Mundhra on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece.h"
#import "Story+Create.h"
#import "Story+Edit.h"
#import "AFParseAPIClient.h"

@interface Piece (Create)
+ (void)createNewPiece:(Piece *)piece afterPiece:(Piece *)previousPiece;

+ (Piece *) newPieceDraftForStory:(Story *)story;

@end

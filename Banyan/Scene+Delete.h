//
//  Scene+Delete.h
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece.h"
#import "Story+Edit.h"
#import "AFParseAPIClient.h"

#define DELETE_PIECE(__piece__)                                                                             \
do {                                                                                                        \
BNOperationObject *obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeScene           \
tempId:__piece__.pieceId                                                                                    \
storyId:__piece__.story.storyId];                                                                           \
BNOperation *op = [[BNOperation alloc] initWithObject:obj action:BNOperationActionDelete dependencies:nil]; \
ADD_OPERATION_TO_QUEUE(op);                                                                                 \
[Piece deleteSceneFromDisk:__piece__];                                                                        \
} while(0)

@interface Piece (Delete)

+ (void) deleteSceneFromDisk:(Piece *)piece;
+ (void) deletePiece:(NSString *)pieceId;

@end

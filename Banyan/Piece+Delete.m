//
//  Scene+Delete.m
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece+Delete.h"
#import "Story.h"
#import "AFBanyanAPIClient.h"

@implementation Piece (Delete)

+ (void) deletePiece:(Piece *)piece
{    
    [[AFBanyanAPIClient sharedClient] deletePath:BANYAN_API_OBJECT_URL(@"Piece", piece.pieceId)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            NSLog(@"Piece with id %@ deleted", piece.pieceId);
                                        }
                                        failure:nil];
    [piece.story.pieces removeObject:piece];
    piece.story.length = [NSNumber numberWithInteger:piece.story.pieces.count];
    if (![piece.story.length integerValue])
        piece.story.pieces = nil;
}
@end

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

- (void) remove
{
    self.story = nil;
    [super remove];
}

+ (void) deletePiece:(Piece *)piece
{    
    [[AFBanyanAPIClient sharedClient] deletePath:BANYAN_API_OBJECT_URL(@"Piece", piece.bnObjectId)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            NSLog(@"Piece with id %@ deleted", piece.bnObjectId);
                                        }
                                        failure:nil];
    
    [piece.story removePiecesObject:piece];
    piece.story.length = [NSNumber numberWithInteger:piece.story.pieces.count];
    if (![piece.story.length integerValue])
        piece.story.pieces = nil;
    
    // Delete the piece
    [piece remove];
}
@end

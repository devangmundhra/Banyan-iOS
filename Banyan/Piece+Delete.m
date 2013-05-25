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
    Story *story = piece.story;
    
    [[AFBanyanAPIClient sharedClient] deletePath:BANYAN_API_OBJECT_URL(@"Piece", piece.bnObjectId)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            NSLog(@"Piece deleted with response %@", responseObject);
                                        }
                                        failure:nil];
    
    // Delete the piece
    [piece remove];
    
    // Update the length
    story.length = [NSNumber numberWithInteger:story.pieces.count];
    // Update the value for the piece numbers
    if (![story.length integerValue])
        story.pieces = nil;
    else {
        [story.pieces enumerateObjectsUsingBlock:^(Piece *localPiece, NSUInteger idx, BOOL *stop) {
            localPiece.pieceNumber = [NSNumber numberWithUnsignedInteger:idx+1];
        }];
    }
}
@end

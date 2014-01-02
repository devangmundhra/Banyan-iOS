//
//  Scene+Create.m
//  Storied
//
//  Created by Devang Mundhra on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece+Create.h"
#import "Piece+Edit.h"
#import "Piece_Defines.h"
#import "Story_Defines.h"
#import "Media.h"
#import "User.h"
#import "User_Defines.h"
#import "Story+Permissions.h"

@implementation Piece (Create)

+ (Piece *) newPieceForStory:(Story *)story
{
    Piece *piece = [[Piece alloc] initWithEntity:[NSEntityDescription entityForName:kBNPieceClassKey
                                                             inManagedObjectContext:[story managedObjectContext]]
                  insertIntoManagedObjectContext:[story managedObjectContext]];
    
    piece.story = story;
    
    if (![piece.story.pieces containsObject:piece]) {
        NSLog(@"Something is wrong here");
    }
    return piece;
}

+ (Piece *) newPieceDraftForStory:(Story *)story
{
    Piece *piece = [self newPieceForStory:story];
    piece.remoteStatus = RemoteObjectStatusLocal;
    piece.author = [User currentUser];
    piece.createdAt = piece.updatedAt = [NSDate date];
    piece.timeStamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate]];
    
//    [piece save];
    
    return piece;
}

+ (void) createNewPiece:(Piece *)piece
{
    assert(!NUMBER_EXISTS(piece.bnObjectId));
    
    if (piece.remoteStatus == RemoteObjectStatusLocal) {
        [Story syncStoryAttributeWithItsPIeces:piece.story];
    }
    
    piece.remoteStatus = RemoteObjectStatusPushing;
    
    [piece save];
    
    // If the story of the piece has not been updated yet, don't do anything. Just fail.
    // Someone else will comeback later and create this
    if (piece.story.remoteStatus != RemoteObjectStatusSync) {
        piece.remoteStatus = RemoteObjectStatusFailed;
        [piece save];
        return;
    }
    
    NSLog(@"Adding piece %@ for story %@", piece, piece.story);
    
    [[RKObjectManager sharedManager] postObject:piece
                                           path:nil
                                     parameters:nil
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                            piece.remoteStatus = RemoteObjectStatusSync;
                                            NSLog(@"Create piece successful %@", piece);
//                                            [piece save];
                                            if ([piece.media count]) {
                                                // Media should be uploaded asynchronously.
                                                // So edit the piece now which will in turn upload the media.
                                                [Piece editPiece:piece];
                                            }
                                        }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                            piece.remoteStatus = RemoteObjectStatusFailed;
//                                            [piece save];
                                            NSLog(@"Error in create piece");
                                        }];
    
    // Save this story in the UserDefaults so that next time the user will add a piece here.
    [piece.story saveStoryMOIdToUserDefaults];
    [piece save];
}

@end

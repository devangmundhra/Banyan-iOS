//
//  Scene+Create.m
//  Storied
//
//  Created by Devang Mundhra on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece+Create.h"
#import "Piece+Delete.h"
#import "Media.h"
#import "User.h"
#import "Story+Permissions.h"
#import "Piece+Stats.h"

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

    return piece;
}

+ (void) createNewPiece:(Piece *)piece
{
    assert(!NUMBER_EXISTS(piece.bnObjectId));
    
    if (piece.remoteStatus == RemoteObjectStatusLocal) {
        [Story syncStoryAttributeWithItsPieces:piece.story];
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
    
    // Block to upload the piece
    void (^createPiece)(Piece *) = ^(Piece *piece) {
        NSLog(@"Adding piece %@ for story %@", piece, piece.story);
        
        [[RKObjectManager sharedManager] postObject:piece
                                               path:nil
                                         parameters:nil
                                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                piece.remoteStatus = RemoteObjectStatusSync;
                                                NSLog(@"Create piece successful %@", piece);
                                                [Piece viewedPiece:piece];
                                            }
                                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                piece.remoteStatus = RemoteObjectStatusFailed;
                                                if ([[error localizedDescription] rangeOfString:@"got 400"].location != NSNotFound) {
                                                    if ([[error localizedRecoverySuggestion] rangeOfString:piece.story.resourceUri].location != NSNotFound) {
                                                        // The story is no longer available on the server. This is now a local copy
                                                        piece.remoteStatus = RemoteObjectStatusLocal;
                                                        [[[UIAlertView alloc] initWithTitle:@"Error in creating piece"
                                                                                    message:[NSString stringWithFormat:@"The story has already been deleted by someone so the piece \"%@\" will be dropped", piece.shortText?:piece.longText?:@""]
                                                                                   delegate:nil
                                                                          cancelButtonTitle:@"OK"
                                                                          otherButtonTitles:nil]
                                                         show];
                                                        [Piece deletePiece:piece completion:nil];
                                                    }
                                                }
                                                NSLog(@"Error in create piece");
                                            }];
    };
    
    if ([piece.media count]) {
        // If all the media haven't been uploaded yet, don't edit the piece
        
        BOOL mediaBeingUploaded = NO;
        for (Media *media in piece.media) {
            if ([media.localURL length]) {
                assert(media.remoteStatus != MediaRemoteStatusSync);
                
                // If the story doesn't have any media yet, use this image for story media
                // A new upload of media will occur for the story
                [piece.story updateMediaIfRequiredWithMediaSet:piece.media];
                
                if (media.remoteStatus == MediaRemoteStatusProcessing || media.remoteStatus == MediaRemoteStatusPushing) {
                    mediaBeingUploaded = YES;
                    continue;
                }
                // Upload the media then update the piece
                [media
                 uploadWithSuccess:^{
                     NSLog(@"Successfully uploaded %@ [%@] when creating piece %@", media.mediaTypeName, media.filename, piece.shortText.length ? piece.shortText : @"");
                     piece.remoteStatus = RemoteObjectStatusPushing; // So that the new piece can be uploaded now with all the media
                     [Piece createNewPiece:piece];
                 }
                 failure:^(NSError *error) {
                     piece.remoteStatus = RemoteObjectStatusFailed;
                     [piece save];
                     NSLog(@"Error uploading %@ [%@] when creating piece %@", media.mediaTypeName, media.filename, piece.shortText.length ? piece.shortText : @"");
                 }];
                mediaBeingUploaded = YES;
            }
        }
        // Media is being uploaded
        if (mediaBeingUploaded)
            return;
        
        // All the media has been uploaded. So the createPiece can happen now
        createPiece(piece);
    }
    // No media changed.
    else {
        createPiece(piece);
    }
    
    // Save this story in the UserDefaults so that next time the user will add a piece here.
    [piece.story saveStoryMOIdToUserDefaults];
    [piece save];
}

@end

//
//  Piece+Edit.m
//  Banyan
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "Story.h"
#import "Piece+Edit.h"
#import "Media+Transfer.h"
#import "BNMisc.h"
#import "Piece+Delete.h"
#import "Piece+Create.h"

@implementation Piece (Edit)

+ (void) editPiece:(Piece *)piece
{
    [piece save];
    
    // If the object has not been created yet, create it first.
    if (!NUMBER_EXISTS(piece.bnObjectId)) {
        if (piece.remoteStatus == RemoteObjectStatusPushing) {
            // Cancel any current POST operations going on
            [piece cancelAnyOngoingOperation];
            [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction Skipped" action:@"piece edit" label:@"pending changes" value:nil];
            return;
        }
        // Now since this story has not yet been created, create if first
        [Piece createNewPiece:piece];
        return;
    }
    
    piece.remoteStatus = RemoteObjectStatusPushing;
    
    BNLogInfo(@"Trying to update piece %@", piece.bnObjectId);
    
    // Block to upload the piece
    void (^updatePiece)(Piece *) = ^(Piece *piece) {
        BNLogTrace(@"Update piece %@ for story %@", piece, piece.story);
        
        RKObjectRequestOperation *operation = [[RKObjectManager sharedManager] appropriateObjectRequestOperationWithObject:piece method:RKRequestMethodPUT path:nil parameters:nil];

        [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            BNLogTrace(@"Update piece successful %@", piece);
            piece.remoteStatus = RemoteObjectStatusSync;
            piece.ongoingOperation = nil;
            [piece save];
        }
                                         failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                             BNLogError(@"Error in updating piece");
                                             piece.remoteStatus = RemoteObjectStatusFailed;
                                             piece.ongoingOperation = nil;
                                             [piece save];
                                             if ([[error localizedDescription] rangeOfString:@"got 400"].location != NSNotFound) {
                                                 if ([[error localizedRecoverySuggestion] rangeOfString:piece.story.resourceUri].location != NSNotFound) {
                                                     // The story is no longer available on the server. This is now a local copy
                                                     piece.remoteStatus = RemoteObjectStatusLocal;
                                                     [[[UIAlertView alloc] initWithTitle:@"Error in updating piece"
                                                                                 message:[NSString stringWithFormat:@"The story has already been deleted so the piece \"%@\" will be dropped", piece.shortText?:piece.longText?:@""]
                                                                                delegate:nil
                                                                       cancelButtonTitle:@"OK"
                                                                       otherButtonTitles:nil]
                                                      show];
                                                     [Piece deletePiece:piece completion:nil];
                                                 }
                                             }
                                         }];
        piece.ongoingOperation = operation;
        [[RKObjectManager sharedManager] enqueueObjectRequestOperation:operation];
    };
    
    if ([piece.media count]) {
        // If all the media haven't been uploaded yet, don't edit the piece
        
        BOOL mediaBeingUploaded = NO;
        for (Media *media in piece.media) {
            if ([media.localURL length]) {
                assert(media.remoteStatus != MediaRemoteStatusSync);
                
                if (media.remoteStatus == MediaRemoteStatusProcessing || media.remoteStatus == MediaRemoteStatusPushing) {
                    mediaBeingUploaded = YES;
                    continue;
                }
                // Upload the media then update the piece
                [media
                 uploadWithSuccess:^{
                     BNLogTrace(@"Successfully uploaded %@ [%@] when editing piece %@", media.mediaTypeName, media.filename, piece.shortText.length ? piece.shortText : @"");
                     piece.remoteStatus = RemoteObjectStatusFailed; // So that this is called again to update the media array
                     [Piece editPiece:piece];
                 }
                 failure:^(NSError *error) {
                     piece.remoteStatus = RemoteObjectStatusFailed;
                     [piece save];
                     BNLogError(@"Error uploading %@ [%@] when editing piece %@", media.mediaTypeName, media.filename, piece.shortText.length ? piece.shortText : @"");
                 }];
                mediaBeingUploaded = YES;
            }
        }
        // Media is being uploaded
        if (mediaBeingUploaded)
            return;
        
        // All the media has been uploaded. So the editPiece can happen now
        updatePiece(piece);
    }
    // No media changed.
    else {
        updatePiece(piece);
    }
    
    [piece save];
}

@end

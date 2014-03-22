//
//  Story+Edit.m
//  Storied
//
//  Created by Devang Mundhra on 3/21/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "Story+Edit.h"
#import "Media+Transfer.h"
#import "Story+Create.h"
#import "Story+Delete.h"
#import "BanyanAppDelegate.h"

@implementation Story (Edit)

+ (void) syncStoryAttributeWithItsPieces:(Story *)story
{
    if (story.currentPieceIndexNum >= story.length)
    /*
     * Correct the story currentPieceIndexNum if required.
     * This can be needed if for example a piece was deleted but the currentPieceIndexNum of the story
     * wasn't updated. For example,
     * 1. A story is fetched from the backend
     * 2. The story is deleted in the backend
     * 3. On the phone, the story is opened and a piece inserted in the middle
     * 4. Since the story has been deleted, createPiece will delete this piece after it has updated story.currentPueceNumber
     * 5. So the currentPieceIndexNum might be more than the number of objects in story.pieces
     */
        story.currentPieceIndexNum = 0;
    
    // Update the value for the piece numbers
    if (!story.length)
        story.pieces = nil;
    else {
        [story.pieces enumerateObjectsUsingBlock:^(Piece *localPiece, NSUInteger idx, BOOL *stop) {
            if (story.timeStamp < localPiece.timeStamp) {
                story.timeStamp = localPiece.timeStamp;
            }
        }];
    }    
}

+ (void) editStory:(Story *)story
{
    [story save];

    // If the object has not been created yet, don't ask for editing it on the server.
    if (!NUMBER_EXISTS(story.bnObjectId)) {
        if (story.remoteStatus == RemoteObjectStatusPushing) {
            // TODO: There is still a race condition here when the story is being created
            // and an edit comes in, in which case the edit will be lost.
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't update the story"
                                                            message:@"A previous syncronization of the story to the server is still in progress"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        // Else don't do anything. The story has not even been created yet. So the creation of the story will take care of the edit as well.
        return;
    }
    
    story.remoteStatus = RemoteObjectStatusPushing;
    
    BNLogInfo(@"Trying to update story %@", story.bnObjectId);
    
    // Block to upload the story
    void (^updateStory)(Story *) = ^(Story *story) {
        BNLogTrace(@"Edit Story %@", story);
        
        [[RKObjectManager sharedManager] putObject:story
                                              path:nil
                                        parameters:nil
                                           success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                               BNLogTrace(@"Update story successful %@", story);
                                               story.remoteStatus = RemoteObjectStatusSync;
                                               // Be eager in uploading pieces if available
                                               [APP_DELEGATE fireRemoteObjectTimer];
                                           }
                                           failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                               story.remoteStatus = RemoteObjectStatusFailed;
                                               if ([[error localizedDescription] rangeOfString:@"got 400"].location != NSNotFound) {
                                                   // The story is no longer available on the server. This is now a local copy
                                                   story.remoteStatus = RemoteObjectStatusLocal;
                                                   [Story deleteStory:story completion:nil];
                                                   [[[UIAlertView alloc] initWithTitle:@"Error in story update"
                                                                               message:@"This story has already been deleted and so the changes to the story will be dropped"
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil]
                                                    show];
                                               }
                                               BNLogError(@"Error in updating story %@", story.bnObjectId);
                                           }];
    };
    
    if ([story.media count]) {
        // Story should only have 1 media at most
        assert(story.media.count <= 1);
        
        // If all the media haven't been uploaded yet, don't edit the story
        BOOL mediaBeingUploaded = NO;
        for (Media *media in story.media) {
            if ([media.localURL length]) {
                assert(media.remoteStatus != MediaRemoteStatusSync);
                
                if (media.remoteStatus == MediaRemoteStatusProcessing || media.remoteStatus == MediaRemoteStatusPushing) {
                    mediaBeingUploaded = YES;
                    continue;
                }
                // Upload the media then update the story
                [media
                 uploadWithSuccess:^{
                     BNLogTrace(@"Successfully uploaded %@ [%@] when editing story %@", media.mediaTypeName, media.filename, story.title);
                     story.remoteStatus = RemoteObjectStatusFailed; // So that this is called again to update the media array
                     [Story editStory:story];
                 }
                 failure:^(NSError *error) {
                     story.remoteStatus = RemoteObjectStatusFailed;
                     [story save];
                     BNLogError(@"Error uploading %@ [%@] when editing story %@", media.mediaTypeName, media.filename, story.title);
                 }];
                mediaBeingUploaded = YES;
            }
        }
        // Media is being uploaded
        if (mediaBeingUploaded)
            return;
        
        // All the media has been uploaded. So the editStory can happen now
        updateStory(story);
    }
    // No media changed.
    else {
        updateStory(story);
    }

    [story save];
}

@end

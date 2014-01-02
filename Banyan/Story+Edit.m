//
//  Story+Edit.m
//  Storied
//
//  Created by Devang Mundhra on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Edit.h"
#import "Media.h"
#import "BanyanDataSource.h"
#import "Story+Create.h"
#import "Story+Delete.h"

@implementation Story (Edit)

+ (void) syncStoryAttributeWithItsPIeces:(Story *)story
{
    // Update the length
    story.length = story.pieces.count;
    // Update the value for the piece numbers
    if (!story.length)
        story.pieces = nil;
    else {
        [story.pieces enumerateObjectsUsingBlock:^(Piece *localPiece, NSUInteger idx, BOOL *stop) {
            localPiece.pieceNumber = idx+1;
            if (story.timeStamp < localPiece.timeStamp) {
                story.timeStamp = localPiece.timeStamp;
            }
        }];
    }
    
    [story save];
}

+ (void) editStory:(Story *)story
{
    [story save];

    // If the object has not been created yet, don't ask for editing it on the server.
    if (!NUMBER_EXISTS(story.bnObjectId)) {
        // TODO: There is still a race condition here when the story is being created
        // and an edit comes in
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't synchronize the story with the server."
                                                        message:@"A previous synchronization is going on. Try in a bit!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    story.remoteStatus = RemoteObjectStatusPushing;
    
    NSLog(@"Trying to update story %@", story.bnObjectId);
    
    // Block to upload the story
    void (^updateStory)(Story *) = ^(Story *story) {
        NSLog(@"Edit Story %@", story);
        
        [[RKObjectManager sharedManager] putObject:story
                                              path:nil
                                        parameters:nil
                                           success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                               NSLog(@"Update story successful %@", story);
                                               story.remoteStatus = RemoteObjectStatusSync;
                                               [story save];
                                           }
                                           failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                               story.remoteStatus = RemoteObjectStatusFailed;
                                               if ([[error localizedDescription] rangeOfString:@"got 400"].location != NSNotFound) {
                                                   // The story is no longer available on the server. This is now a local copy
                                                   story.remoteStatus = RemoteObjectStatusLocal;
                                                   [Story deleteStory:story completion:nil];
                                               }
                                               NSLog(@"Error in updating story");
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
                     NSLog(@"Successfully uploaded %@ [%@] when editing story %@", media.mediaTypeName, media.filename, story.title);
                     story.remoteStatus = RemoteObjectStatusFailed; // So that this is called again to update the media array
                     [Story editStory:story];
                 }
                 failure:^(NSError *error) {
                     story.remoteStatus = RemoteObjectStatusFailed;
                     [story save];
                     NSLog(@"Error uploading %@ [%@] when editing story %@", media.mediaTypeName, media.filename, story.title);
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

- (void) updateMediaIfRequiredWithMediaSet:(NSOrderedSet *)mediaSet
{
    // Check if the story already has a media object, if so, don't do anything
    if (self.media.count) {
        return;
    }
    
    // Check if any of the media in this set been uploaded, if so, use that url and filename
    for (Media *media in mediaSet) {
        if ([media.mediaType isEqualToString:@"image"] && media.remoteStatus == MediaRemoteStatusLocal) {
            NSAssert1(media.localURL.length, @"Media not available for story %@ without length", self.title);
            
            Media *newMedia = [Media newMediaForObject:self];
            [newMedia cloneFrom:media];
            [Story editStory:self];
            return;
        }
        
    }
}

@end

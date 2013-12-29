//
//  Scene+Edit.m
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import "Piece+Edit.h"
#import "Story_Defines.h"
#import "Media.h"
#import "BNMisc.h"
#import "Story+Edit.h"

@implementation Piece (Edit)

+ (void) editPiece:(Piece *)piece
{
    [piece save];
    
    // If the object has not been created yet, don't ask for editing it on the server.
    if (!NUMBER_EXISTS(piece.bnObjectId)) {
        // TODO: There is still a race condition here when the piece is being created
        // and an edit comes in
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't synchronize the piece with the server."
                                                        message:@"A previous synchronization is going on. Try in a bit!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    piece.remoteStatus = RemoteObjectStatusPushing;
    
    NSLog(@"Trying to update piece %@", piece.bnObjectId);
    
    // Block to upload the piece
    void (^updatePiece)(Piece *) = ^(Piece *piece) {
        NSLog(@"Update piece %@ for story %@", piece, piece.story);
        
        [[RKObjectManager sharedManager] putObject:piece
                                              path:nil
                                        parameters:nil
                                           success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                               NSLog(@"Update piece successful %@", piece);
                                               piece.remoteStatus = RemoteObjectStatusSync;
                                               [piece save];
                                           }
                                           failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                               NSLog(@"Error in updating piece");
                                               piece.remoteStatus = RemoteObjectStatusFailed;
                                               [piece save];
                                           }];
    };
    
    if ([piece.media count]) {
//        if (![piece createGifFileIfReqdAndShouldContinue])
//            return;
        
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
                     NSLog(@"Successfully uploaded %@ [%@] when editing piece %@", media.mediaTypeName, media.filename, piece.shortText.length ? piece.shortText : @"");
                     piece.remoteStatus = RemoteObjectStatusFailed; // So that this is called again to update the media array
                     [Piece editPiece:piece];
                 }
                 failure:^(NSError *error) {
                     piece.remoteStatus = RemoteObjectStatusFailed;
                     [piece save];
                     NSLog(@"Error uploading %@ [%@] when editing piece %@", media.mediaTypeName, media.filename, piece.shortText.length ? piece.shortText : @"");
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

- (BOOL) createGifFileIfReqdAndShouldContinue
{
    // Create gif if required
    // If there is not already a gif file present in the media list and number of image media is more than one,
    // a gif file needs to be created
    NSOrderedSet *imageMediaSet = [Media getAllMediaOfType:@"image" inMediaSet:self.media];
    if (imageMediaSet.count <= 1) {
        NSLog(@"Won't be needing any gif");
        return YES;
    }
    
    Media *gifMedia = [Media getMediaOfType:@"gif" inMediaSet:self.media];
    if (gifMedia) {
        NSLog(@"Won't be needing any gif creation");
        return YES; // No need to creating anything new
    }
    
    // If there is already a request to create a new gif, don't do anything now
    if (self.creatingGifFromMedia) {
        NSLog(@"Gif creation already in progress");
        return NO;
    }
    
    self.creatingGifFromMedia = YES;
    __block NSMutableArray *mediaArray = [NSMutableArray array];
    for (int i = 0; i < imageMediaSet.count; i++) {
        [mediaArray addObject:[NSNull null]];
    }
    
    __block unsigned int numImagesSuccessfullyObtained = 0;
    __block unsigned int numImageFetchResults = 0;

    NSLog(@"Creating gif!");
    
    // Get all the images
    [imageMediaSet enumerateObjectsUsingBlock:^(Media *media, NSUInteger idx, BOOL *stop) {
        [media getImageForMediaWithSuccess:^(UIImage *image){
            [mediaArray replaceObjectAtIndex:idx withObject:image];
            numImagesSuccessfullyObtained++;
            numImageFetchResults++;
        }
                                   failure:^(NSError *error) {
                                       NSLog(@"Error %@ in creating images", error.localizedDescription);
                                       numImageFetchResults++;
                                   }];
    }];

    dispatch_queue_t waitQueue = dispatch_queue_create("io.banyan.waitForDownloadingPictures", NULL);
    dispatch_async(waitQueue, ^{
        while (numImageFetchResults < imageMediaSet.count) {
            sleep(1); // sleep for a second
        }
        
        assert(imageMediaSet.count == numImageFetchResults);
        
        if (imageMediaSet.count == numImagesSuccessfullyObtained) {
            dispatch_async(dispatch_get_main_queue(), ^{ // Do image processing in main queue only
                // Create a gif
                NSString *gifUrl = [BNMisc gifFromArray:mediaArray];
                if (gifUrl) {
                    // Add the new piece
                    Media *media = [Media newMediaForObject:self];
                    media.mediaType = @"gif";
                    media.localURL = gifUrl;
                } else {
                    NSLog(@"Problem in creating a new gif after getting all images");
                }
                self.creatingGifFromMedia = NO;
                self.remoteStatus = RemoteObjectStatusFailed;
                [self save];
            });
        } else {
            NSLog(@"Error in creating gif. Couln't fetch all images to create it.");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.creatingGifFromMedia = NO;
                self.remoteStatus = RemoteObjectStatusFailed;
                [self save];
            });
        }
    });
    return NO;
}

@end

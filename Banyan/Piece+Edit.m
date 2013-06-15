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
#import "AFBanyanAPIClient.h"
#import "Media.h"

@implementation Piece (Edit)

+ (void) editPiece:(Piece *)piece
{
    [piece save];
    
    // If the object has not been created yet, don't ask for editing it on the server.
    if (!piece.bnObjectId.length) {
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

    NSLog(@"Update piece %@ for story %@", piece, piece.story);
    
    // Block to upload the piece
    void (^updatePiece)(Piece *) = ^(Piece *piece) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        // For serializing
        RKObjectMapping *pieceRequestMapping = [RKObjectMapping requestMapping];
        [pieceRequestMapping addAttributeMappingsFromArray:@[PIECE_LONGTEXT, PIECE_SHORTTEXT, @"isLocationEnabled"]];
        
        RKObjectMapping *locationMapping = [RKObjectMapping requestMapping];
        [locationMapping addAttributeMappingsFromArray:@[@"id", @"category", @"name"]];
        RKObjectMapping *locationLocationMapping = [RKObjectMapping requestMapping];
        [locationLocationMapping addAttributeMappingsFromArray:@[@"street", @"city", @"state", @"country", @"zip", @"latitude", @"longitude"]];
        [locationMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationLocationMapping]];
        [pieceRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationMapping]];
        
        RKObjectMapping *mediaMapping = [RKObjectMapping requestMapping];
        [mediaMapping addAttributeMappingsFromDictionary:@{@"remoteURL": @"url"}];
        [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType"]];
        
        [pieceRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media" toKeyPath:@"media" withMapping:mediaMapping]];
        
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                                  requestDescriptorWithMapping:pieceRequestMapping
                                                  objectClass:[Piece class]
                                                  rootKeyPath:nil];
        RKEntityMapping *pieceResponseMapping = [RKEntityMapping mappingForEntityForName:kBNPieceClassKey
                                                                    inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [pieceResponseMapping addAttributeMappingsFromArray:@[PARSE_OBJECT_UPDATED_AT]];
        
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:pieceResponseMapping
                                                                                           pathPattern:nil
                                                                                               keyPath:nil
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addRequestDescriptor:requestDescriptor];
        [objectManager addResponseDescriptor:responseDescriptor];
        
        [objectManager putObject:piece
                             path:BANYAN_API_OBJECT_URL(@"Piece", piece.bnObjectId)
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
        BOOL mediaBeingUploaded = NO;
        for (Media *media in piece.media) {
            if ([media.localURL length]) {
                // Upload the media then update the piece
                [media
                 uploadWithSuccess:^{
                     updatePiece(piece);
                 }
                 failure:^(NSError *error) {
                     piece.remoteStatus = RemoteObjectStatusFailed;
                     [piece save];
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error uploading %@ when editing piece %@", media.mediaTypeName, piece.shortText]
                                                                     message:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
                     [alert show];
                 }];
                mediaBeingUploaded = YES;
            }
        }
        // Media wasn't changed
        if (!mediaBeingUploaded) {
            updatePiece(piece);
        }
    }
    // No media changed.
    else {
        updatePiece(piece);
    }
    
    [piece save];
}

@end

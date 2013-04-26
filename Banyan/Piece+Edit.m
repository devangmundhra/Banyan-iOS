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
#import "AFParseAPIClient.h"
#import "Media.h"

@implementation Piece (Edit)

+ (void) editPiece:(Piece *)piece
{
    if (piece.remoteStatus != RemoteObjectStatusSync)
        return;
    
    NSLog(@"Update piece %@ for story %@", piece, piece.story);
    
    // Block to upload the piece
    void (^updatePiece)(Piece *) = ^(Piece *piece) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFParseAPIClient sharedClient]];
        // For serializing
        RKObjectMapping *pieceRequestMapping = [RKObjectMapping requestMapping];
        [pieceRequestMapping addAttributeMappingsFromArray:@[PIECE_LONGTEXT, PIECE_SHORTTEXT, PIECE_IMAGE_URL, PIECE_IMAGE_NAME, PIECE_LATITUDE, PIECE_LONGITUDE, PIECE_GEOCODEDLOCATION]];
        
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
                             path:PARSE_API_OBJECT_URL(@"Piece", piece.bnObjectId)
                       parameters:nil
                          success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              NSLog(@"Update piece successful %@", piece);
                          }
                          failure:^(RKObjectRequestOperation *operation, NSError *error) {
                              NSLog(@"Error in create piece");
                          }];
    };
    
    if ([piece.media.localURL length]) {
        // Upload the image then update the piece
        [piece.media
         uploadWithSuccess:^{
            updatePiece(piece);
        }
         failure:^(NSError *error) {
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in finding Image"
                                                             message:[NSString stringWithFormat:@"Can't find Asset Library image. Error: %@", error.localizedDescription]
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
                                   [alert show];
                               }];
    }
    // Image wasn't changed.
    else {
        updatePiece(piece);
    }
}

@end

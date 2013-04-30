//
//  Scene+Create.m
//  Storied
//
//  Created by Devang Mundhra on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece+Create.h"
#import "Piece_Defines.h"
#import "Story_Defines.h"
#import "AFBanyanAPIClient.h"
#import "Media.h"

@implementation Piece (Create)

+ (Piece *) newPieceForStory:(Story *)story
{
    Piece *piece = [[Piece alloc] initWithEntity:[NSEntityDescription entityForName:kBNPieceClassKey
                                                          inManagedObjectContext:[story managedObjectContext]]
               insertIntoManagedObjectContext:[story managedObjectContext]];
    
    piece.story = story;
    
    return piece;
}

+ (Piece *) newPieceDraftForStory:(Story *)story
{
    Piece *piece = [self newPieceForStory:story];
    piece.remoteStatus = RemoteObjectStatusLocal;
    piece.authorId = [PFUser currentUser].objectId;
    piece.createdAt = piece.updatedAt = [NSDate date];
    
    [piece save];
    
    return piece;
}

+ (void) createNewPiece:(Piece *)piece afterPiece:(Piece *)previousPiece
{    
    piece.story.length = [NSNumber numberWithInteger:piece.story.pieces.count];
    [piece.story.pieces enumerateObjectsUsingBlock:^(Piece *localPiece, NSUInteger idx, BOOL *stop) {
        localPiece.pieceNumber = [NSNumber numberWithUnsignedInteger:idx+1];
    }];
    
    [piece save];
    NSLog(@"Adding scene %@ for story %@", piece, piece.story);
    
    // Block to upload the piece
    void (^uploadPiece)(Piece *) = ^(Piece *piece) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        // For serializing
        RKObjectMapping *pieceRequestMapping = [RKObjectMapping requestMapping];
        [pieceRequestMapping addAttributeMappingsFromDictionary:@{@"authorId" : PIECE_AUTHOR, @"story.bnObjectId" : PIECE_STORY}];
        [pieceRequestMapping addAttributeMappingsFromArray:@[PIECE_LONGTEXT, PIECE_SHORTTEXT, @"isLocationEnabled"]];
        
        RKObjectMapping *locationMapping = [RKObjectMapping requestMapping];
        [locationMapping addAttributeMappingsFromArray:@[@"id", @"category", @"name"]];
        RKObjectMapping *locationLocationMapping = [RKObjectMapping requestMapping];
        [locationLocationMapping addAttributeMappingsFromArray:@[@"street", @"city", @"state", @"country", @"zip", @"latitude", @"longitude"]];
        [locationMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationLocationMapping]];
        [pieceRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationMapping]];
        
        RKObjectMapping *mediaMapping = [RKObjectMapping requestMapping];
        [mediaMapping addAttributeMappingsFromDictionary:@{@"remoteURL": @"url"}];
        [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width"]];
        [pieceRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media" toKeyPath:@"media" withMapping:mediaMapping]];
        
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                                  requestDescriptorWithMapping:pieceRequestMapping
                                                  objectClass:[Piece class]
                                                  rootKeyPath:nil];
        RKEntityMapping *pieceResponseMapping = [RKEntityMapping mappingForEntityForName:kBNPieceClassKey
                                                                    inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [pieceResponseMapping addAttributeMappingsFromDictionary:@{
                                                PARSE_OBJECT_ID : @"bnObjectId",
         }];
        [pieceResponseMapping addAttributeMappingsFromArray:@[PARSE_OBJECT_CREATED_AT, PARSE_OBJECT_UPDATED_AT, PIECE_NUMBER]];
        pieceResponseMapping.identificationAttributes = @[@"bnObjectId"];
        
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:pieceResponseMapping
                                                                                           pathPattern:nil
                                                                                               keyPath:nil
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addRequestDescriptor:requestDescriptor];
        [objectManager addResponseDescriptor:responseDescriptor];
        
        piece.remoteStatus = RemoteObjectStatusPushing;
        [objectManager postObject:piece
                             path:BANYAN_API_CLASS_URL(@"Piece")
                       parameters:nil
                          success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              NSLog(@"Create piece successful %@", piece);
                              piece.remoteStatus = RemoteObjectStatusSync;
                              [piece save];
                          }
                          failure:^(RKObjectRequestOperation *operation, NSError *error) {
                              piece.remoteStatus = RemoteObjectStatusFailed;
                              NSLog(@"Error in create piece");
                          }];
    };
    
    // Upload the file and then upload the story
    if ([piece.media.localURL length]) {
        [piece.media uploadWithSuccess:^{
            uploadPiece(piece);
            NSLog(@"Image saved on server");
        }
                               failure:^(NSError *error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in finding Image"
                                                            message:[NSString stringWithFormat:@"Can't find Asset Library image. Error: %@", error.localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }];
    } else {
        uploadPiece(piece);
    }
}

@end

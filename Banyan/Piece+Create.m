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
#import "File.h"

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
        [pieceRequestMapping addAttributeMappingsFromArray:@[PIECE_LONGTEXT, PIECE_SHORTTEXT, PIECE_IMAGE_URL, PIECE_IMAGE_NAME, PIECE_LATITUDE, PIECE_LONGITUDE, PIECE_GEOCODEDLOCATION]];
        [pieceRequestMapping addAttributeMappingsFromDictionary:@{@"authorId" : PIECE_AUTHOR, @"story.bnObjectId" : PIECE_STORY}];
        
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
    if (piece.imageURL) {
        [File uploadFileForLocalURL:piece.imageURL
                       block:^(BOOL succeeded, NSString *newURL, NSString *newName, NSError *error) {
                           if (succeeded) {
                               piece.imageURL = newURL;
                               piece.imageName = newName;
                               uploadPiece(piece);
                               NSLog(@"Image saved on server");
                           } else {
                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in uploading image"
                                                                               message:[NSString stringWithFormat:@"Can't upload the image due to error %@", error.localizedDescription]
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil];
                               [alert show];
                           }
                       }
                         errorBlock:^(NSError *error) {
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
    
//    return piece;
}

@end

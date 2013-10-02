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
#import "AFBanyanAPIClient.h"
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
        [Story updateLengthAndPieceNumbers:piece.story];
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
    
    // Block to upload the piece
    void (^uploadPiece)(Piece *) = ^(Piece *piece) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        // For serializing
        RKObjectMapping *pieceRequestMapping = [RKObjectMapping requestMapping];
        [pieceRequestMapping addAttributeMappingsFromDictionary:@{@"author.resourceUri" : @"author", @"story.resourceUri" : PIECE_STORY}];
        [pieceRequestMapping addAttributeMappingsFromArray:@[PIECE_LONGTEXT, PIECE_SHORTTEXT, @"isLocationEnabled", @"timeStamp"]];
        
        RKObjectMapping *locationMapping = [RKObjectMapping requestMapping];
        [locationMapping addAttributeMappingsFromArray:@[@"id", @"category", @"name"]];
        RKObjectMapping *locationLocationMapping = [RKObjectMapping requestMapping];
        [locationLocationMapping addAttributeMappingsFromArray:@[@"street", @"city", @"state", @"country", @"zip", @"latitude", @"longitude"]];
        [locationMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationLocationMapping]];
        [pieceRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationMapping]];

        // Media, if any, should be uploaded via edit piece, not here. This is so that empty media entities are not created in the backend.
//        RKObjectMapping *mediaMapping = [RKObjectMapping requestMapping];
//        [mediaMapping addAttributeMappingsFromDictionary:@{@"remoteURL": @"url"}];
//        [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType"]];
//        [pieceRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media" toKeyPath:@"media" withMapping:mediaMapping]];
        
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                                  requestDescriptorWithMapping:pieceRequestMapping
                                                  objectClass:[Piece class]
                                                  rootKeyPath:nil
                                                  method:RKRequestMethodPOST];
        
        RKEntityMapping *pieceResponseMapping = [RKEntityMapping mappingForEntityForName:kBNPieceClassKey
                                                                    inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [pieceResponseMapping addAttributeMappingsFromDictionary:@{@"resource_uri": @"resourceUri"}];
        [pieceResponseMapping addAttributeMappingsFromArray:@[@"createdAt", @"updatedAt", PIECE_NUMBER, @"permaLink", @"bnObjectId"]];
        pieceResponseMapping.identificationAttributes = @[@"bnObjectId"];
        
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:pieceResponseMapping
                                                                                                method:RKRequestMethodPOST
                                                                                           pathPattern:nil
                                                                                               keyPath:nil
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addRequestDescriptor:requestDescriptor];
        [objectManager addResponseDescriptor:responseDescriptor];
        
        [objectManager postObject:piece
                             path:BANYAN_API_CLASS_URL(@"Piece")
                       parameters:nil
                          success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              NSLog(@"Create piece successful %@", piece);
                              piece.remoteStatus = RemoteObjectStatusSync;
                              [piece save];
                              if ([piece.media count]) {
                                  // Media should be uploaded asynchronously.
                                  // So edit the piece now which will in turn upload the media.
                                  [Piece editPiece:piece];
                              }
                          }
                          failure:^(RKObjectRequestOperation *operation, NSError *error) {
                              piece.remoteStatus = RemoteObjectStatusFailed;
                              [piece save];
                              NSLog(@"Error in create piece");
                          }];
    };
    
    uploadPiece(piece);
    
    // Save this story in the UserDefaults so that next time the user will add a piece here.
    [piece.story saveStoryMOIdToUserDefaults];
    [piece save];
}

@end

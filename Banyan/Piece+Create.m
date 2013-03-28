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
#import "User+Edit.h"

@implementation Piece (Create)

+ (void) createNewPiece:(Piece *)piece afterPiece:(Piece *)previousPiece
{
//    // Persist so that it can be refetched in persistentStoreManagedObjectContext
//    [piece persistToDatabase];
//    
//    // Change the context to persistentStoreManagedObjectContext
//    piece = (Piece *)[[RKManagedObjectStore defaultStore].persistentStoreManagedObjectContext objectWithID:piece.objectID];
    
    piece.initialized = [NSNumber numberWithBool:NO];
    piece.author = [User currentUser];
    piece.createdAt = piece.updatedAt = [NSDate date];
    
    piece.story.length = [NSNumber numberWithInteger:piece.story.pieces.count];
    
    // Persist again
    [piece persistToDatabase];
    NSLog(@"Adding scene %@ for story %@", piece, piece.story);
    
    // Block to upload the piece
    void (^uploadPiece)(Piece *) = ^(Piece *piece) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        // For serializing
        RKObjectMapping *pieceRequestMapping = [RKObjectMapping requestMapping];
        [pieceRequestMapping addAttributeMappingsFromArray:@[PIECE_LONGTEXT, PIECE_SHORTTEXT, PIECE_IMAGE_URL, PIECE_IMAGE_NAME, PIECE_LATITUDE, PIECE_LONGITUDE, PIECE_GEOCODEDLOCATION]];
        [pieceRequestMapping addAttributeMappingsFromDictionary:@{@"author.userId" : PIECE_AUTHOR, @"story.bnObjectId" : PIECE_STORY}];
        
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
        
        [objectManager postObject:piece
                             path:BANYAN_API_CLASS_URL(@"Piece")
                       parameters:nil
                          success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              NSLog(@"Create piece successful %@", piece);
                              piece.initialized = [NSNumber numberWithBool:YES];
                              [piece persistToDatabase];
                          }
                          failure:^(RKObjectRequestOperation *operation, NSError *error) {
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

- (void)persistToDatabase
{
    [self.managedObjectContext performBlockAndWait:^{
        // Persist the story
        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error: %@", error);
            assert(false);
        };
    }];
    
    [self.managedObjectContext.parentContext performBlockAndWait:^{
        // Persist the piece on the parent context so that it is picked up by Fetched Results Controller
        NSError *error = nil;
        if (![self.managedObjectContext.parentContext save:&error]) {
            NSLog(@"Error: %@", error);
            assert(false);
        };
    }];
}

@end

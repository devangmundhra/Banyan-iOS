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

+ (void)createNewPiece:(Piece *)piece afterPiece:(Piece *)previousPiece
{
    piece.author = [User currentUser];
    NSLog(@"Adding scene %@ for story %@", piece, piece.story);
    
    // Block to upload the piece
    void (^uploadPiece)(Piece *) = ^(Piece *piece) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        // For serializing
        RKObjectMapping *pieceRequestMapping = [RKObjectMapping requestMapping];
        [pieceRequestMapping addAttributeMappingsFromArray:@[PIECE_TEXT, PIECE_IMAGE_URL, PIECE_IMAGE_NAME, PIECE_LATITUDE, PIECE_LONGITUDE, PIECE_GEOCODEDLOCATION]];
        [pieceRequestMapping addAttributeMappingsFromDictionary:@{@"author.userId" : PIECE_AUTHOR, @"story.storyId" : PIECE_STORY}];
        
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                                  requestDescriptorWithMapping:pieceRequestMapping
                                                  objectClass:[Piece class]
                                                  rootKeyPath:nil];
        RKObjectMapping *pieceResponseMapping = [RKObjectMapping mappingForClass:[Piece class]];
        [pieceResponseMapping addAttributeMappingsFromDictionary:@{
                                                PARSE_OBJECT_ID : @"pieceId",
         }];
        [pieceResponseMapping addAttributeMappingsFromArray:@[PARSE_OBJECT_CREATED_AT, PARSE_OBJECT_UPDATED_AT, PIECE_NUMBER]];
        
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
                              piece.initialized = YES;
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
    
    if (!piece.story.pieces) {
        piece.story.pieces = [NSMutableArray array];
    }
    [piece.story.pieces addObject:piece];
    piece.story.length = [NSNumber numberWithInteger:piece.story.pieces.count];
}

@end

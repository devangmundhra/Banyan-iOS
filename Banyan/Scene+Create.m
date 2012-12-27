//
//  Scene+Create.m
//  Storied
//
//  Created by Devang Mundhra on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene+Create.h"
#import "Scene_Defines.h"
#import "Story_Defines.h"
#import "AFBanyanAPIClient.h"

@implementation Piece (Create)

+ (void)createNewPiece:(Piece *)piece afterPiece:(Piece *)previousPiece
{
    piece.author = [User currentUser];
    NSLog(@"Adding scene %@ for story %@", piece, piece.story);
    
    
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    // For serializing
    RKObjectMapping *pieceRequestMapping = [RKObjectMapping requestMapping];
    [pieceRequestMapping addAttributeMappingsFromArray:@[PIECE_TEXT, PIECE_IMAGE_URL, PIECE_NUMBER, PIECE_LATITUDE, PIECE_LONGITUDE, PIECE_GEOCODEDLOCATION]];
    [pieceRequestMapping addAttributeMappingsFromDictionary:@{@"author.userId" : PIECE_AUTHOR, @"story.storyId" : PIECE_STORY}];
    
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                              requestDescriptorWithMapping:pieceRequestMapping
                                              objectClass:[Piece class]
                                              rootKeyPath:nil];
    RKObjectMapping *pieceResponseMapping = [RKObjectMapping mappingForClass:[Piece class]];
    [pieceResponseMapping addAttributeMappingsFromDictionary:@{
     PARSE_OBJECT_ID : @"pieceId",
     }];
    [pieceResponseMapping addAttributeMappingsFromArray:@[PARSE_OBJECT_CREATED_AT, PARSE_OBJECT_UPDATED_AT]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:pieceResponseMapping
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addRequestDescriptor:requestDescriptor];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    [objectManager postObject:piece
                         path:@"Piece"
                   parameters:nil
                      success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                          NSLog(@"Create piece successful %@", piece);
                          piece.initialized = YES;
                          if (!piece.story.pieces) {
                              piece.story.pieces = [NSMutableArray array];
                          }
                          [piece.story.pieces addObject:piece];
                      }
                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
                          NSLog(@"Error in create piece");
                      }];
    
}

@end

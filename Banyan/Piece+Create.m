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
#import "UIImage+ResizeAdditions.h"

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
    };
    
    // Upload the file and then upload the story
    if (piece.imageURL) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library assetForURL:[NSURL URLWithString:piece.imageURL] resultBlock:^(ALAsset *asset) {
            NSData *imageData;
            PFFile *imageFile = nil;
            
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            CGImageRef imageRef = [rep fullScreenImage]; // not fullResolutionImage
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            
            // For now, compress the image before sending.
            // When PUT API is done, compress on the server
            // TODO
            UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:[[UIScreen mainScreen] bounds].size interpolationQuality:kCGInterpolationLow];
            
            imageData = UIImageJPEGRepresentation(resizedImage, 1);
            imageFile = [PFFile fileWithData:imageData];
            
            [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    piece.imageURL = imageFile.url;
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
            }];
        }
                failureBlock:^(NSError *error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in finding Image"
                                                                    message:[NSString stringWithFormat:@"Can't find Asset Library image. Error: %@", error.localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                }
         ];
    } else {
        uploadPiece(piece);
    }
}

@end

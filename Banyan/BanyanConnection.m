//
//  BanyanConnection.m
//  Banyan
//
//  Created by Devang Mundhra on 11/11/12.
//
//

#import "BanyanConnection.h"
#import "AFBanyanAPIClient.h"
#import "BNOperationQueue.h"
#import "Story_Defines.h"

@implementation BanyanConnection

+ (void)loadStoriesFromBanyanWithSuccessBlock:(void (^)(NSMutableArray *stories))successBlock errorBlock:(void (^)(NSError *error))errorBlock
{
    NSString *getPath = BANYAN_API_GET_PUBLIC_STORIES();
    if ([User currentUser]) {
        getPath = BANYAN_API_GET_USER_STORIES([User currentUser]);
    }
    
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    
    RKObjectMapping *storyMapping = [RKObjectMapping mappingForClass:[Story class]];
    [storyMapping addAttributeMappingsFromDictionary:@{
     STORY_CAN_VIEW : @"canView",
     STORY_CAN_CONTRIBUTE : @"canContribute",
     STORY_IS_INVITED: @"invited",
     PARSE_OBJECT_ID : @"storyId",
     STORY_LOCATION_ENABLED: @"isLocationEnabled",
     }];
    
    [storyMapping addAttributeMappingsFromArray:@[STORY_TITLE, STORY_READ_ACCESS, STORY_WRITE_ACCESS, STORY_TAGS, STORY_LENGTH,
                                                    STORY_IMAGE_URL, STORY_GEOCODEDLOCATION, STORY_LATITUDE, STORY_LONGITUDE,
                                                    PARSE_OBJECT_CREATED_AT, PARSE_OBJECT_UPDATED_AT]];
    
    //  @"object.author" : @"author.userId"
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[User class]];
    [userMapping addAttributeMappingsFromDictionary:@{@"": @"userId"}];
    
    RKRelationshipMapping *userRelationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:STORY_AUTHOR toKeyPath:@"author" withMapping:userMapping];
    [storyMapping addPropertyMapping:userRelationshipMapping];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:storyMapping
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    [objectManager getObjectsAtPath:getPath
                         parameters:nil
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                NSArray *stories = [mappingResult array];
                                [stories enumerateObjectsUsingBlock:^(Story *story, NSUInteger idx, BOOL *stop) {
                                    story.initialized = YES;
                                }];
                                successBlock([stories mutableCopy]);                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                errorBlock(error);
                            }];
}

+ (void) loadPiecesForStory:(Story *)story completionBlock:(void (^)())completionBlock errorBlock:(void (^)(NSError *error))errorBlock
{
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    
    RKObjectMapping *pieceMapping = [RKObjectMapping mappingForClass:[Piece class]];
    [pieceMapping addAttributeMappingsFromArray:@[PIECE_IMAGE_URL, PIECE_NUMBER, PIECE_TEXT, PIECE_LATITUDE, PIECE_LONGITUDE, PIECE_GEOCODEDLOCATION,
                                                    PARSE_OBJECT_CREATED_AT, PARSE_OBJECT_UPDATED_AT]];
    [pieceMapping addAttributeMappingsFromDictionary:@{PARSE_OBJECT_ID : @"pieceId"}];
    
    //  @"object.author" : @"author.userId"
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[User class]];
    [userMapping addAttributeMappingsFromDictionary:@{@"": @"userId"}];
    
    RKRelationshipMapping *userRelationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:PIECE_AUTHOR toKeyPath:@"author" withMapping:userMapping];
    [pieceMapping addPropertyMapping:userRelationshipMapping];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:pieceMapping
                                                                                       pathPattern:nil
                                                                                           keyPath:@"pieces"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    [objectManager getObjectsAtPath:BANYAN_API_GET_PIECES_FOR_STORY()
                         parameters:[NSDictionary dictionaryWithObject:story.storyId forKey:@"storyId"]
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                NSArray *pieces = [mappingResult array];
                                [pieces enumerateObjectsUsingBlock:^(Piece *piece, NSUInteger idx, BOOL *stop){
                                    piece.story = story;
                                }];
                                story.pieces = [NSMutableArray arrayWithArray:pieces];
                                story.length = [NSNumber numberWithInteger:pieces.count];
                                completionBlock();
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                errorBlock(error);
                            }];
}

+ (void) resetPermissionsForStories:(NSMutableArray *)stories
{
    for (Story *story in stories)
    {
        [story resetPermission];
    }
}

@end

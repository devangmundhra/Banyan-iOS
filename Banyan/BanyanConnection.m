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

+ (void)loadStoriesFromBanyanWithBlock:(void (^)(NSMutableArray *stories))successBlock
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
    
    [storyMapping addAttributeMappingsFromArray:@[STORY_TITLE, STORY_READ_ACCESS, STORY_WRITE_ACCESS, STORY_TAGS,
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
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                message:[error localizedDescription]
                                                                               delegate:nil
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil];
                                [alert show];
                                NSLog(@"Hit error: %@", error);
                            }];
}

+ (void) loadPiecesForStory:(Story *)story
{
    
}

+ (void) resetPermissionsForStories:(NSMutableArray *)stories
{
    for (Story *story in stories)
    {
        [story resetPermission];
    }
}

@end

//
//  Activity+Create.m
//  Banyan
//
//  Created by Devang Mundhra on 12/31/12.
//
//

#import "Activity+Create.h"
#import "AFBanyanAPIClient.h"
#import "Story_Defines.h"

@implementation Activity (Create)

+ (void)createActivity:(Activity *)activity
{
    if (!(activity.pieceId || activity.storyId) && ![activity.type isEqualToString:kBNActivityTypeFollowUser]) {
        return;
    }
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    // For serializing
    RKObjectMapping *activityMapping = [RKObjectMapping requestMapping];
    [activityMapping addAttributeMappingsFromArray:@[kBNActivityTypeKey, kBNActivityFromUserKey, kBNActivityToUserKey, kBNActivityPieceKey, kBNActivityStoryKey]];
    
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                              requestDescriptorWithMapping:activityMapping
                                              objectClass:[Activity class]
                                              rootKeyPath:nil];
    
    RKObjectMapping *activityResponseMapping = [RKObjectMapping mappingForClass:[Activity class]];
    [activityResponseMapping addAttributeMappingsFromDictionary:@{PARSE_OBJECT_ID : @"activityId"}];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:activityResponseMapping
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [objectManager addRequestDescriptor:requestDescriptor];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    [objectManager postObject:activity
                         path:BANYAN_API_CLASS_URL(@"Activity")
                   parameters:nil
                      success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                          NSLog(@"Create activity successful %@", activity);
                          activity.initialized = YES;
                      }
                      failure:^(RKObjectRequestOperation *operation, NSError *error) {
                          NSLog(@"Error in create activity");
                      }];
}

@end

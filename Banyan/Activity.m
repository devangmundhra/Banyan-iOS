//
//  Activity.m
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import "Activity.h"
#import "AFBanyanAPIClient.h"
#import "Story_Defines.h"

@implementation Activity

@synthesize type = _type;
@synthesize fromUser = _fromUser;
@synthesize toUser = _toUser;
@synthesize sceneId = _sceneId;
@synthesize storyId = _storyId;
@synthesize initialized = _initialized;

+ (Activity *) activityWithType:(NSString *)type
                       fromUser:(NSString *)fromUser
                         toUser:(NSString *)toUser
                        sceneId:(NSString *)sceneId
                        storyId:(NSString *)storyId
{
    Activity *newActivity = [[Activity alloc] init];
    newActivity.type = type;
    newActivity.fromUser = fromUser;
    newActivity.toUser = toUser;
    newActivity.sceneId = sceneId;
    newActivity.storyId = storyId;
    
    return newActivity;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.type forKey:kBNActivityTypeKey];
    [encoder encodeObject:self.fromUser forKey:kBNActivityFromUserKey];
    [encoder encodeObject:self.toUser forKey:kBNActivityToUserKey];
    [encoder encodeObject:self.sceneId forKey:kBNActivitySceneKey];
    [encoder encodeObject:self.storyId forKey:kBNActivityStoryKey];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.type = [decoder decodeObjectForKey:kBNActivityTypeKey];
        self.fromUser = [decoder decodeObjectForKey:kBNActivityFromUserKey];
        self.toUser = [decoder decodeObjectForKey:kBNActivityToUserKey];
        self.sceneId = [decoder decodeObjectForKey:kBNActivitySceneKey];
        self.storyId = [decoder decodeObjectForKey:kBNActivityStoryKey];
    }
    return self;
}

+ (void)createActivity:(Activity *)activity
{

    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    // For serializing
    RKObjectMapping *activityMapping = [RKObjectMapping requestMapping];
    [activityMapping addAttributeMappingsFromArray:@[kBNActivityTypeKey, kBNActivityFromUserKey, kBNActivityToUserKey, kBNActivitySceneKey, kBNActivityStoryKey]];
    
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

+ (void)deleteActivity:(Activity *)activity
{    
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    // For serializing
    RKObjectMapping *activityMapping = [RKObjectMapping requestMapping];
    [activityMapping addAttributeMappingsFromArray:@[kBNActivityTypeKey, kBNActivityFromUserKey, kBNActivityToUserKey, kBNActivitySceneKey, kBNActivityStoryKey]];
    
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

    [objectManager deleteObject:activity
                           path:BANYAN_API_CLASS_URL(@"Activity")
                     parameters:nil
                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                            NSLog(@"Delete activity successful %@", activity);
                            activity.initialized = YES;
                        }
                        failure:^(RKObjectRequestOperation *operation, NSError *error) {
                            NSLog(@"Error in delete activity activity");
                        }];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{Activity\n type: %@ fromUser: %@, toUser: %@, sceneId: %@, storyId: %@\n}",
            self.type, self.fromUser, self.toUser, self.sceneId, self.storyId];
}

@end

//
//  Activity.m
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import "Activity.h"

@implementation Activity

@synthesize type = _type;
@synthesize object = _object;
@synthesize resourceUri = _resourceUri;

+ (Activity *) activityWithType:(NSString *)type
                         object:(NSString *)object
{
    Activity *newActivity = [[Activity alloc] init];
    newActivity.type = type;
    newActivity.object = object;
    
    return newActivity;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.type forKey:kBNActivityTypeKey];
    [encoder encodeObject:self.object forKey:kBNActivityObjectKey];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.type = [decoder decodeObjectForKey:kBNActivityTypeKey];
        self.object = [decoder decodeObjectForKey:kBNActivityObjectKey];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{Activity %@(%@)\n type: %@ object: %@\n}",
            self.activityId, self.resourceUri, self.type, self.object];
}

+ (RKObjectMapping *)activityRequestMappingForRKPOST
{
    RKObjectMapping *activityMapping = [RKObjectMapping requestMapping];
    [activityMapping addAttributeMappingsFromArray:@[kBNActivityTypeKey]];
    [activityMapping addAttributeMappingsFromDictionary:@{kBNActivityObjectKey: @"content_object"}];
    
    return activityMapping;
}

+ (RKObjectMapping *)activityResponseMappingForRKPOST
{
    RKObjectMapping *activityResponseMapping = [RKObjectMapping mappingForClass:[Activity class]];
    [activityResponseMapping addAttributeMappingsFromDictionary:@{@"id" : @"activityId", @"resource_uri": @"resourceUri"}];
    
    return activityResponseMapping;
}

+ (void)createActivity:(Activity *)activity withCompletionBlock:(void (^)(bool succeeded, NSString *resourceUri, NSError *error))block;
{
    NSAssert1(activity.object, @"No object to create an activity of type", activity.type);
    NSAssert1(![activity.type isEqualToString:kBNActivityTypeFollowUser] && ![activity.type isEqualToString:kBNActivityTypeUnfollowUser], @"Invalid activity of type", activity.type);
    
    [[RKObjectManager sharedManager] postObject:activity
                                           path:nil
                                     parameters:nil
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                            if (block) block(YES, activity.resourceUri, nil);
                                        }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                            BNLogError(@"Error in create activity %@", activity);
                                            if (block) block(NO, nil, error);
                                        }];
}

+ (void) deleteActivityAtResourceUri:(NSString *)resourceUri withCompletionBlock:(void (^)(bool succeeded, NSError *error))block
{
    [[RKObjectManager sharedManager] deleteObject:nil
                                             path:resourceUri
                                       parameters:nil
                                          success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                              if (block) block(YES, nil);
                                          }
                                          failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                              if (block) block(NO, error);
                                          }];
}

@end

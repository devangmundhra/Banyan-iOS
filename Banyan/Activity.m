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
    return [NSString stringWithFormat:@"{Activity\n type: %@ object: %@\n}",
            self.type, self.object];
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
    [activityResponseMapping addAttributeMappingsFromDictionary:@{@"id" : @"activityId"}];
    
    return activityResponseMapping;
}

@end

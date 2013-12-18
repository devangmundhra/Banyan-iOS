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
@synthesize fromUser = _fromUser;
@synthesize toUser = _toUser;
@synthesize piece = _piece;
@synthesize story = _story;
@synthesize initialized = _initialized;

+ (Activity *) activityWithType:(NSString *)type
                       fromUser:(NSString *)fromUser
                         toUser:(NSString *)toUser
                          piece:(NSString *)piece
                          story:(NSString *)story
{
    Activity *newActivity = [[Activity alloc] init];
    newActivity.type = type;
    newActivity.fromUser = fromUser;
    newActivity.toUser = toUser;
    newActivity.piece = piece;
    newActivity.story = story;
    
    return newActivity;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.type forKey:kBNActivityTypeKey];
    [encoder encodeObject:self.fromUser forKey:kBNActivityFromUserKey];
    [encoder encodeObject:self.toUser forKey:kBNActivityToUserKey];
    [encoder encodeObject:self.piece forKey:kBNActivityPieceKey];
    [encoder encodeObject:self.story forKey:kBNActivityStoryKey];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.type = [decoder decodeObjectForKey:kBNActivityTypeKey];
        self.fromUser = [decoder decodeObjectForKey:kBNActivityFromUserKey];
        self.toUser = [decoder decodeObjectForKey:kBNActivityToUserKey];
        self.piece = [decoder decodeObjectForKey:kBNActivityPieceKey];
        self.story = [decoder decodeObjectForKey:kBNActivityStoryKey];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{Activity\n type: %@ fromUser: %@, toUser: %@, piece: %@, story: %@\n}",
            self.type, self.fromUser, self.toUser, self.piece, self.story];
}

+ (RKObjectMapping *)activityRequestMappingForRKPOST
{
    RKObjectMapping *activityMapping = [RKObjectMapping requestMapping];
    [activityMapping addAttributeMappingsFromArray:@[kBNActivityTypeKey, kBNActivityFromUserKey, kBNActivityToUserKey, kBNActivityPieceKey, kBNActivityStoryKey]];
    
    return activityMapping;
}

+ (RKObjectMapping *)activityResponseMappingForRKPOST
{
    RKObjectMapping *activityResponseMapping = [RKObjectMapping mappingForClass:[Activity class]];
    [activityResponseMapping addAttributeMappingsFromDictionary:@{@"id" : @"activityId"}];
    
    return activityResponseMapping;
}

@end

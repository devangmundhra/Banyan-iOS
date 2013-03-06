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
@synthesize pieceId = _pieceId;
@synthesize storyId = _storyId;
@synthesize initialized = _initialized;

+ (Activity *) activityWithType:(NSString *)type
                       fromUser:(NSString *)fromUser
                         toUser:(NSString *)toUser
                        pieceId:(NSString *)pieceId
                        storyId:(NSString *)storyId
{
    Activity *newActivity = [[Activity alloc] init];
    newActivity.type = type;
    newActivity.fromUser = fromUser;
    newActivity.toUser = toUser;
    newActivity.pieceId = pieceId;
    newActivity.storyId = storyId;
    
    return newActivity;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.type forKey:kBNActivityTypeKey];
    [encoder encodeObject:self.fromUser forKey:kBNActivityFromUserKey];
    [encoder encodeObject:self.toUser forKey:kBNActivityToUserKey];
    [encoder encodeObject:self.pieceId forKey:kBNActivityPieceKey];
    [encoder encodeObject:self.storyId forKey:kBNActivityStoryKey];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.type = [decoder decodeObjectForKey:kBNActivityTypeKey];
        self.fromUser = [decoder decodeObjectForKey:kBNActivityFromUserKey];
        self.toUser = [decoder decodeObjectForKey:kBNActivityToUserKey];
        self.pieceId = [decoder decodeObjectForKey:kBNActivityPieceKey];
        self.storyId = [decoder decodeObjectForKey:kBNActivityStoryKey];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{Activity\n type: %@ fromUser: %@, toUser: %@, pieceId: %@, storyId: %@\n}",
            self.type, self.fromUser, self.toUser, self.pieceId, self.storyId];
}

@end

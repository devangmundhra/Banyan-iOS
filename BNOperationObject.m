//
//  BNOperationObject.m
//  Banyan
//
//  Created by Devang Mundhra on 7/25/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BNOperationObject.h"

@implementation BNOperationObject

@synthesize type = _type;
@synthesize tempId = _tempId;
@synthesize storyId = _storyId;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _type = [aDecoder decodeIntForKey:@"type"];
        _tempId = [aDecoder decodeObjectForKey:@"tempId"];
        _storyId = [aDecoder decodeObjectForKey:@"storyId"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:_type forKey:@"type"];
    [aCoder encodeObject:_tempId forKey:@"tempId"];
    [aCoder encodeObject:_storyId forKey:@"storyId"];
}


- (id)initWithObjectType:(BNOperationObjectType)type 
                  tempId:(NSString *)tempId
                 storyId:(NSString *)storyId
{	
    if((self = [super init])) {
        _type = type;
        _tempId = tempId;
        _storyId = storyId;
    }
    
    return self;
}

- (BOOL) isObjectInitialized
{
    id object;
    
    switch (self.type) {
        case BNOperationObjectTypeScene:
            object = [BanyanDataSource lookForSceneId:self.tempId inStoryId:self.storyId];
            break;
            
        case BNOperationObjectTypeStory:
            object = [BanyanDataSource lookForStoryId:self.tempId];
            break;
            
        case BNOperationObjectTypeFile:
            object = [[File alloc] initWithUrl:self.tempId];
            break;
            
        case BNOperationObjectTypeUser:
            object = [User userWithId:self.tempId];
            break;
            
        default:
            break;
    }

    if ([object respondsToSelector:@selector(initialized)]) {
        BOOL isInit = [object initialized];
        NSLog(@"%s self: %@\n object: %@\n initialized: %d ", __PRETTY_FUNCTION__, self, object, isInit);
        return isInit;
    }
    else {
        NSLog(@"%s self: %@\n object (unid): %@\n initialized: 0 ", __PRETTY_FUNCTION__, self, object);
        return NO;
    }
}

// Change so that objects can be compared
- (NSUInteger)hash
{
    // Mostly the different tempIds will never be the same. So don't worry about type
    return [self.tempId hash];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToBNOperationObject:other];
}

- (BOOL)isEqualToBNOperationObject:(BNOperationObject *)object
{
    if (self == object  )
        return YES;
    if (![UPDATED(self.tempId) isEqualToString:UPDATED(object.tempId)] || (self.type != object.type) || ![UPDATED(self.storyId) isEqualToString:UPDATED(object.storyId)])
        return NO;
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Id: %@\n Type: %@", self.tempId, [self typeString]];
}

- (NSString *)typeString
{
    switch (self.type) {
        case BNOperationObjectTypeScene:
            return @"Scene";
            break;
            
        case BNOperationObjectTypeStory:
            return @"Story";
            break;
            
        case BNOperationObjectTypeUser:
            return @"User";
            break;
            
        case BNOperationObjectTypeFile:
            return @"File";
            break;
            
        default:
            return @"Unknown type";
            break;
    }
}
@end
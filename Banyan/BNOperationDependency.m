//
//  BNOperationDependency.m
//  Banyan
//
//  Created by Devang Mundhra on 7/25/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BNOperationDependency.h"

@implementation BNOperationDependency

@synthesize object = _object;
@synthesize field = _field;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _object = [aDecoder decodeObjectForKey:@"object"];
        _field = [aDecoder decodeObjectForKey:@"field"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_object forKey:@"object"];
    [aCoder encodeObject:_field forKey:@"field"];
}

- (id)initWithObjectType:(BNOperationObjectType)type 
                  tempId:(NSString *)tempId
                 storyId:(NSString *)storyId
                   field:(NSString *)field
{	
    if((self = [super init])) {
        _object = [[BNOperationObject alloc] initWithObjectType:type tempId:tempId storyId:storyId];
        _field = field;
    }
    
    return self;
}

- (id)initWithBNObject:(BNOperationObject *)object
                 field:(NSString *)field
{
    if((self = [super init])) {
        _object = [[BNOperationObject alloc] initWithObjectType:object.type
                                                         tempId:object.tempId
                                                        storyId:object.storyId];
        _field = field;
    }
    
    return self;
}

// Change so that objects can be compared
- (NSUInteger)hash
{
    return [self.object.tempId hash] & [self.field hash];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToBNDependencyObject:other];
}

- (BOOL)isEqualToBNDependencyObject:(BNOperationDependency *)object
{
    if (self == object  )
        return YES;
    if (![self.object isEqual:object.object] || (self.field != object.field))
        return NO;
    return YES;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"Dep Object: %@\n Field: %@", self.object, self.field];
}

- (void)dealloc
{
    NSLog(@"Deallocating dependency %@", self);
}

@end

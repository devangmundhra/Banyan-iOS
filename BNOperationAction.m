//
//  BNOperationAction.m
//  Banyan
//
//  Created by Devang Mundhra on 7/25/12.
//
//

#import "BNOperationAction.h"

@implementation BNOperationAction

@synthesize actionType = _actionType;
@synthesize context = _context;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _actionType = [aDecoder decodeIntForKey:@"action"];
        _context = [aDecoder decodeObjectForKey:@"context"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:_actionType forKey:@"action"];
    [aCoder encodeObject:_context forKey:@"context"];
}

- (id)initWithActionType:(BNOperationActionType)action;
{
    if((self = [super init])) {
        _actionType = action;
        _context = nil;
    }
    
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"{Action: %@\n Context: %@}",
            self.actionType == 1 ? @"Create" : (self.actionType == 2 ? @"Edit" : (self.actionType == 3 ? @"IncAttr" : @"Delete")),
            self.context];
}

@end

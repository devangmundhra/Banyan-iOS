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
    return [NSString stringWithFormat:@"{Action: %@\n Context: %@}", [self typeString], self.context];
}

- (NSString *)typeString
{
    switch (self.actionType) {
        case BNOperationActionCreate:
            return @"Creating";
            break;
            
        case BNOperationActionDelete:
            return @"Deleting";
            break;
            
        case BNOperationActionEdit:
            return @"Editing";
            break;
            
        case BNOperationActionIncrementAttribute:
            return @"Increment Attribute";
            break;
            
        default:
            return @"Unknown action";
            break;
    }
}

@end

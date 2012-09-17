//
//  BNOperationAction.h
//  Banyan
//
//  Created by Devang Mundhra on 7/25/12.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    BNOperationActionCreate = 1,
    BNOperationActionEdit = 2,
    BNOperationActionIncrementAttribute = 3,
    BNOperationActionDelete = 4
} BNOperationActionType;

@interface BNOperationAction : NSObject <NSCoding>

@property (assign)  BNOperationActionType actionType;
@property (strong, atomic) id context;

- (id)initWithActionType:(BNOperationActionType)action;
- (NSString *)typeString;
@end

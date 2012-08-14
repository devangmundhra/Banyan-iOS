//
//  BNOperation.h
//  Banyan
//
//  Created by Devang Mundhra on 7/15/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNOperationObject.h"
#import "BNOperationAction.h"
#import "BNOperationDependency.h"

@interface BNOperation : NSOperation <NSCoding>

@property (strong, nonatomic) BNOperationObject *object;
@property (strong, nonatomic) BNOperationAction *action;
@property (strong, nonatomic) NSMutableSet *dependency;

- (id)initWithObject:(BNOperationObject *)object
              action:(BNOperationActionType)action
        dependencies:(NSMutableSet *)dependency;
- (void)addDependencyObject:(BNOperationDependency *)object;
- (void)removeDependencyObject:(BNOperationDependency *)object;
- (BOOL)checkDependencyForObject:(BNOperationDependency *)object;
- (void)completeOperationWithError:(BOOL)error;

@end

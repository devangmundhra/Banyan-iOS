//
//  BNOperationDependency.h
//  Banyan
//
//  Created by Devang Mundhra on 7/25/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNOperationObject.h"

@interface BNOperationDependency : NSObject <NSCoding>

@property (strong, atomic) BNOperationObject *object;
@property (strong, atomic) NSString *field;

- (id)initWithObjectType:(BNOperationObjectType)type 
                  tempId:(NSString *)tempId
                 storyId:(NSString *)storyId
                   field:(NSString *)field;
@end

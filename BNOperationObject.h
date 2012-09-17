//
//  BNOperationObject.h
//  Banyan
//
//  Created by Devang Mundhra on 7/25/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BanyanDataSource.h"

typedef enum {
    BNOperationObjectTypeScene = 1,
    BNOperationObjectTypeStory = 2,
    BNOperationObjectTypeUser = 3,
    BNOperationObjectTypeFile = 4,
    BNOperationObjectTypeActivity = 5,
} BNOperationObjectType;

@interface BNOperationObject : NSObject <NSCoding>

@property (assign) BNOperationObjectType type;
@property (strong, nonatomic) NSString *tempId;
@property (strong, nonatomic) NSString *storyId;

- (id)initWithObjectType:(BNOperationObjectType)type 
                  tempId:(NSString *)tempId
                 storyId:(NSString *)storyId;

- (BOOL)isObjectInitialized;
- (NSString *)typeString;
@end
//
//  Story+Delete.h
//  Storied
//
//  Created by Devang Mundhra on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import "Scene.h"
#import "AFParseAPIClient.h"

#define DELETE_STORY(__story__) \
do {\
BNOperationObject *obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeStory\
tempId:__story__.storyId\
storyId:__story__.storyId];\
BNOperation *op = [[BNOperation alloc] initWithObject:obj action:BNOperationActionDelete dependencies:nil];\
ADD_OPERATION_TO_QUEUE(op);\
} while(0)

@interface Story (Delete)

+ (void) removeStory:(Story *)story;

@end

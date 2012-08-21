//
//  Scene+Delete.h
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene.h"
#import "Story+Edit.h"
#import "AFParseAPIClient.h"

#define DELETE_SCENE(__scene__)                                                                             \
do {                                                                                                        \
BNOperationObject *obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeScene           \
tempId:__scene__.sceneId                                                                                    \
storyId:__scene__.story.storyId];                                                                           \
BNOperation *op = [[BNOperation alloc] initWithObject:obj action:BNOperationActionDelete dependencies:nil]; \
ADD_OPERATION_TO_QUEUE(op);                                                                                 \
[Scene deleteSceneFromDisk:__scene__];                                                                        \
} while(0)

@interface Scene (Delete)

+ (void) deleteSceneFromDisk:(Scene *)scene;
+ (void) deleteSceneFromServerWithId:(NSString *)sceneId;
+ (void) removeSceneWithId:(NSString *)sceneId;

@end

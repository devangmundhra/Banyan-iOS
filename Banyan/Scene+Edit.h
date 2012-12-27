//
//  Scene+Edit.h
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece.h"
#import <Parse/Parse.h>
#import "Scene_Defines.h"
#import "AFParseAPIClient.h"

#define INCREMENT_SCENE_ATTRIBUTE_OPERATION(__scene__, __attribute__, __amount__) \
do { \
BNOperationObject *obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeScene \
tempId:__scene__.sceneId \
storyId:__scene__.story.storyId]; \
BNOperation *op = [[BNOperation alloc] initWithObject:obj action:BNOperationActionIncrementAttribute dependencies:nil]; \
op.action.context = [NSDictionary dictionaryWithObjectsAndKeys:__attribute__, @"attribute", [NSNumber numberWithInt:__amount__], @"amount", nil]; \
ADD_OPERATION_TO_QUEUE(op); \
} while(0)

@interface Piece (Edit)

+ (void) editScene:(Piece *)scene;
+ (void) editScene:(Piece *)scene withAttributes:(NSMutableDictionary *)sceneParams;
- (void)incrementSceneAttribute:(NSString *)attribute byAmount:(NSNumber *)inc;
@end

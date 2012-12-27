//
//  Story+Edit.h
//  Storied
//
//  Created by Devang Mundhra on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import "Piece.h"
#import "Story_Defines.h"
#import "AFParseAPIClient.h"

#define INCREMENT_STORY_ATTRIBUTE_OPERATION(__story__, __attribute__, __amount__) \
do {\
BNOperationObject *obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeStory\
                                                                tempId:__story__.storyId\
                                                               storyId:__story__.storyId];\
BNOperation *op = [[BNOperation alloc] initWithObject:obj action:BNOperationActionIncrementAttribute dependencies:nil];\
op.action.context = [NSDictionary dictionaryWithObjectsAndKeys:__attribute__, @"attribute", [NSNumber numberWithInt:__amount__], @"amount", nil];\
ADD_OPERATION_TO_QUEUE(op);\
} while(0)

@interface Story (Edit)

+ (void) editStory:(Story *)story;
//- (void) startingSceneForStory:(Scene *)scene;
- (void) incrementStoryAttribute:(NSString *)attribute byAmount:(NSNumber *)inc;
+ (void) editStory:(Story *)story withAttributes:(NSMutableDictionary *)storyParams;

@end

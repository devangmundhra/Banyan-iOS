//
//  Story+Create.h
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import "Piece+Create.h"

@interface Story (Create)

+ (void) createNewStory:(Story *)story;
+ (Story *) newDraftStory;
@end

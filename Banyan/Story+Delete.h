//
//  Story+Delete.h
//  Storied
//
//  Created by Devang Mundhra on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import "Scene.h"
#import <Parse/Parse.h>
#import "ParseAPIEngine.h"

@interface Story (Delete)

+ (void) removeStory:(Story *)story;

@end

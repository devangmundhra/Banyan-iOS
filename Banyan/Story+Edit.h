//
//  Story+Edit.h
//  Storied
//
//  Created by Devang Mundhra on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import "Scene.h"
#import <Parse/Parse.h>
#import "ParseAPIEngine.h"

@interface Story (Edit)

+ (void) editStory:(Story *)story;
- (void) startingSceneForStory:(Scene *)scene;
- (void) incrementStoryAttribute:(NSString *)attribute byAmount:(NSNumber *)inc;

@end

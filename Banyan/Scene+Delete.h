//
//  Scene+Delete.h
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene.h"
#import <Parse/Parse.h>
#import "Story+Edit.h"
#import "ParseAPIEngine.h"

@interface Scene (Delete)

+ (void) removeScene:(Scene *)scene;
+ (void) removeSceneWithId:(NSString *)sceneId;
@end

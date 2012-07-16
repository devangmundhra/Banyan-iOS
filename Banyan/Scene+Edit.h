//
//  Scene+Edit.h
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene.h"
#import <Parse/Parse.h>
#import "ParseAPIEngine.h"

@interface Scene (Edit)

+ (void) editScene:(Scene *)scene;
- (void)incrementSceneAttribute:(NSString *)attribute byAmount:(NSNumber *)inc;
@end

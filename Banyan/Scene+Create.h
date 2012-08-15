//
//  Scene+Create.h
//  Storied
//
//  Created by Devang Mundhra on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene.h"
#import "Story+Create.h"
#import "Story+Edit.h"
#import "AFParseAPIClient.h"

@interface Scene (Create)
+ (Scene *)createSceneForStory:(Story *) story
                    attributes:(NSMutableDictionary *)attributes
                    afterScene:(Scene *)previousScene;
+ (void) createSceneOnServer:(Scene *)scene;

@end

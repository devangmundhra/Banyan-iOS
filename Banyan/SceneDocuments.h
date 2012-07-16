//
//  SceneDocuments.h
//  Storied
//
//  Created by Devang Mundhra on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Scene.h"
#import "Story.h"

@interface SceneDocuments : NSObject

+ (void)saveSceneToDisk:(Scene *)scene;
+ (void)deleteSceneFromDisk:(Scene *)scene;
+ (NSMutableArray *)loadScenesFromDiskForStory:(Story *)story;
+ (NSString *)getPathToSceneDocumentWithScene:(Scene *)scene;

@end

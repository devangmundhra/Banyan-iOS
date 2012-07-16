//
//  StoryDocuments.h
//  Storied
//
//  Created by Devang Mundhra on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Story.h"

@interface StoryDocuments : NSObject

+ (void)saveStoryToDisk:(Story *)story;
+ (void)deleteStoryFromDisk:(Story *)story;
+ (NSMutableArray *)loadStoriesFromDisk;
+ (NSString *)getPathToStoryDocumentWithStory:(Story *)story;
+ (Story *)loadStoryFromDisk:(NSString *)storyId;
+ (void)deleteStoriesFromDisk;

@end

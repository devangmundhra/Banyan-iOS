//
//  Story+Edit.h
//  Storied
//
//  Created by Devang Mundhra on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import "Story_Defines.h"

@interface Story (Edit)

+ (void) syncStoryAttributeWithItsPIeces:(Story *)story;
+ (void) editStory:(Story *)story;
- (void) updateMediaIfRequiredWithMediaSet:(NSOrderedSet *)mediaSet;

@end

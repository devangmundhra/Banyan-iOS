//
//  Story+Edit.h
//  Banyan
//
//  Created by Devang Mundhra on 3/21/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "Story.h"

@interface Story (Edit)

+ (void) syncStoryAttributeWithItsPieces:(Story *)story;
+ (void) editStory:(Story *)story;
- (void) updateMediaIfRequiredWithMediaSet:(NSOrderedSet *)mediaSet;

@end

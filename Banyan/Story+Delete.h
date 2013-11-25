//
//  Story+Delete.h
//  Storied
//
//  Created by Devang Mundhra on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"

@interface Story (Delete)
+ (BOOL) deleteStory:(Story *)story;
@end

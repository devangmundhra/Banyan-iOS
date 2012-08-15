//
//  Story+Create.h
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import "Scene+Create.h"
#import "AFParseAPIClient.h"

@interface Story (Create) <PF_FBDialogDelegate>

+ (Story *)createStoryWithAttributes:(NSMutableDictionary *)attributes;
+ (void) createStoryOnServer:(Story *)story;

@end

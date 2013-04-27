//
//  Story_Defines.h
//  Storied
//
//  Created by Devang Mundhra on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import "Piece_Defines.h"

@interface Story ()

#define STORY_LENGTH @"length"
#define STORY_TITLE @"title"
#define STORY_CONTRIBUTORS @"contributors"
#define STORY_WRITE_ACCESS @"writeAccess"
#define STORY_READ_ACCESS @"readAccess"

#define STORY_CAN_VIEW @"read"
#define STORY_CAN_CONTRIBUTE @"write"
#define STORY_IS_INVITED @"invited"

#define STORY_FONT @"Georgia-BoldItalic"

#define STORY_DATE_CREATED @"createdAt"
#define STORY_DATE_MODIFIED @"updatedAt"
#define STORY_AUTHOR @"author"
#define STORY_TAGS @"tags"

#define PARSE_OBJECT_CREATED_AT @"createdAt"
#define PARSE_OBJECT_UPDATED_AT @"updatedAt"
#define PARSE_OBJECT_ID @"objectId"

@end

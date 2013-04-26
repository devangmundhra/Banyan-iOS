//
//  Story+Delete.m
//  Storied
//
//  Created by Devang Mundhra on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Delete.h"
#import "AFBanyanAPIClient.h"
#import "Story_Defines.h"
#import "BanyanDataSource.h"

@implementation Story (Delete)

+ (void) deleteStory:(Story *)story
{
    NSString *storyId = story.bnObjectId;
    NSLog(@"%s Story id: %@", __PRETTY_FUNCTION__, storyId);
    
    [[AFBanyanAPIClient sharedClient] deletePath:BANYAN_API_OBJECT_URL(@"Story", storyId)
                                      parameters:nil
                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             NSLog(@"Story with id %@ deleted", storyId);
                                         }
                                         failure:nil];
    
    [story remove];
}

@end
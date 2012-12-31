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
#import "File.h"

@implementation Story (Delete)

+ (void) deleteStory:(Story *)story
{
    NSLog(@"%s Story id: %@", __PRETTY_FUNCTION__, story.storyId);
    [[NSNotificationCenter defaultCenter] postNotificationName:STORY_DELETE_STORY_NOTIFICATION
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:story
                                                                                           forKey:@"Story"]];
    
    [[AFBanyanAPIClient sharedClient] deletePath:BANYAN_API_OBJECT_URL(@"Story", story.storyId)
                                      parameters:nil
                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             NSLog(@"Story with id %@ deleted", story.storyId);
                                         }
                                         failure:nil];
    [[BanyanDataSource shared] removeObject:story];
}@end
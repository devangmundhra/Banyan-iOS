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
    NSString *storyId = story.bnObjectId;
    NSLog(@"%s Story id: %@", __PRETTY_FUNCTION__, storyId);
    
    [[AFBanyanAPIClient sharedClient] deletePath:BANYAN_API_OBJECT_URL(@"Story", storyId)
                                      parameters:nil
                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             NSLog(@"Story with id %@ deleted", storyId);
                                         }
                                         failure:nil];
    
    NSManagedObjectContext *storyContext = story.managedObjectContext;
    NSManagedObjectContext *storyContextParent = story.managedObjectContext.parentContext;
    
    [storyContext performBlockAndWait:^{
        [storyContext deleteObject:story];
        NSError *error = nil;
        if (![storyContext save:&error]) {
            NSLog(@"Error: %@", error);
            assert(false);
        }
    }];
    
    [storyContextParent performBlockAndWait:^{
        NSError *error = nil;
        if (![storyContextParent save:&error]) {
            NSLog(@"Error: %@", error);
            assert(false);
        }
    }];
}

@end
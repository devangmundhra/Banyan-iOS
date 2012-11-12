//
//  BanyanConnection.m
//  Banyan
//
//  Created by Devang Mundhra on 11/11/12.
//
//

#import "BanyanConnection.h"
#import "AFBanyanAPIClient.h"
#import "BNOperationQueue.h"

@implementation BanyanConnection

+ (void)loadStoriesFromBanyanWithBlock:(void (^)(NSMutableArray *stories))successBlock
{
    {
        NSMutableArray *dStories = [StoryDocuments loadStoriesFromDisk];
        
        // We need this array because if we go into the network available case, then we filter all the stories
        // which are initialized. But if there are ongoing operations for the story, then they will be skipped
        // when adding from the stories from network too. So we just append this array later.
        NSMutableArray *initializedActiveDStories = [NSMutableArray array];
        
        // There might be some stories in the current BanayanDataSource which are more current than
        // the ones saves on the disk (for example if the network is really slow and this operation is taking a
        // lot of time while an update has arrived in one of the BNOperations), then we should simple get the current stories
        for (int index = 0; index < [dStories count]; index++) {
            for (Story *story in [BanyanDataSource shared]) {
                if ([story.storyId isEqualToString:UPDATED([(Story *)[dStories objectAtIndex:index] storyId])]
                    && [[[BNOperationQueue shared] storyIdsOfActiveOperations] containsObject:story.storyId]) {
                    [dStories replaceObjectAtIndex:index withObject:story];
                    NSLog(@"%s Keeping story with id %@", __PRETTY_FUNCTION__, story.storyId);
                    break;
                }
            }
        }
        
        // If there is no internet connection, load stories from the disk
        if (![[AFBanyanAPIClient sharedClient] isReachable]) {
            NSLog(@"BanyanConnection: Loading stories from disk");
            successBlock(dStories);
        }
        else {
            NSLog(@"BanyanConnection: Loading stories from network");
            if ([[BNOperationQueue shared] operationCount] == 0) {
                [StoryDocuments deleteStoriesFromDisk];
            }
            
            NSString *getPath = BANYAN_API_GET_PUBLIC_STORIES();
            if ([User currentUser]) {
                getPath = BANYAN_API_GET_USER_STORIES([User currentUser]);
            }
            [[AFBanyanAPIClient sharedClient] getPath:getPath
                                           parameters:nil
                                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                  dispatch_queue_t postFetchQueue = dispatch_queue_create("banyan fetch story completion queue", NULL);
                                                  dispatch_async(postFetchQueue, ^ {
                                                      NSMutableArray *pStories = [[NSMutableArray alloc] init];
                                                      NSArray *stories = (NSArray *)responseObject;
                                                      for (NSDictionary *storyDict in stories)
                                                      {
                                                          // Don't do anything if this story has some outstanding operations currently

                                                          if ([[[BNOperationQueue shared] storyIdsOfActiveOperations] containsObject:[storyDict objectForKey:@"objectId"]]) {
                                                              NSLog(@"Skipping getting the story for %@", [storyDict objectForKey:@"objectId"]);
                                                              
                                                              // If this storyId is there in dStories, it will get filtered next (because getting a story from
                                                              // network means the story is intializied) . So save it in a seperte array and then add it to the
                                                              // results later
                                                              for (Story *story in dStories) {
                                                                  if ([UPDATED(story.storyId) isEqualToString:[storyDict objectForKey:@"objectId"]]) {
                                                                      [initializedActiveDStories addObject:story];
                                                                  }
                                                              }
                                                              continue;
                                                          }
                                                          
                                                          Story *story = [[Story alloc] init];
                                                          [story fillAttributesFromDictionary:storyDict];
                                                          [pStories addObject:story];
                                                      }
                                                      // Save the time of last successful update
                                                      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                      [defaults setObject:[NSDate date] forKey:BNUserDefaultsLastSuccessfulStoryUpdateTime];
                                                      
                                                      // Also add the stories that have not been initialized yet
                                                      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(initialized == NO)"];
                                                      [dStories filterUsingPredicate:predicate];
                                                      [pStories addObjectsFromArray:dStories];
                                                      [pStories addObjectsFromArray:initializedActiveDStories];
                                                      successBlock(pStories);
                                                  });
                                                  dispatch_release(postFetchQueue);
                                              }
                                              failure:AF_BANYAN_ERROR_BLOCK()
             ];
        }
    }
}

+ (void) resetPermissionsForStories:(NSMutableArray *)stories
{
    for (Story *story in stories)
    {
        [story resetPermission];
    }
}

@end

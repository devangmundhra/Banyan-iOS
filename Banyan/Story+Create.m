//
//  Story+Create.m
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Create.h"
#import "Story+Permissions.h"
#import "Story_Defines.h"
#import "User_Defines.h"
#import "BanyanDataSource.h"
#import "UIImage+ResizeAdditions.h"
#import "Media.h"
#import "User.h"
#import <CoreData/CoreData.h>

@implementation Story (Create)

+ (Story *) newStory
{
    Story *story = [NSEntityDescription insertNewObjectForEntityForName:kBNStoryClassKey
                                                 inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];
    return story;
}

+ (Story *) newDraftStory
{
    Story *story = [Story newStory];
    story.remoteStatus = RemoteObjectStatusLocal;
    story.author = [User currentUser];
    story.createdAt = story.updatedAt = [NSDate date];
    story.timeStamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate]];
    
//    [story save];
    
    return story;
}

// Upload the given story using RestKit
+ (void)createNewStory:(Story *)story
{
    assert(!NUMBER_EXISTS(story.bnObjectId));
    assert(NUMBER_EXISTS(story.author.userId));
    story.canContribute = story.canView = YES;
    
    story.remoteStatus = RemoteObjectStatusPushing;
    
    // Persist again
    [story save];
    
    NSLog(@"Adding story %@", story);

    [[RKObjectManager sharedManager] postObject:story
                                           path:nil
                                     parameters:nil
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                            NSLog(@"Create story successful %@", story);
                                            story.remoteStatus = RemoteObjectStatusSync;
                                            if ([story.media count]) {
                                                // Media should be uploaded asynchronously.
                                                // So edit the story now which will in turn upload the media.
                                                [Story editStory:story];
                                            }
                                            [story save];
                                        }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                            story.remoteStatus = RemoteObjectStatusFailed;
                                            [story save];
                                            NSLog(@"Error in create story");
                                        }];

    // Save this story in the UserDefaults so that next time the user will add a piece here.
    [story saveStoryMOIdToUserDefaults];
}

@end

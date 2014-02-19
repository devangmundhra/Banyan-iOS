//
//  Story+Create.m
//  Banyan
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "Story+Create.h"
#import "Story+Permissions.h"
#import "UIImage+ResizeAdditions.h"
#import "Media.h"
#import "User.h"
#import "Story+Stats.h"

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

    return story;
}

// Upload the given story using RestKit
+ (void)createNewStory:(Story *)story
{
    assert(!NUMBER_EXISTS(story.bnObjectId));
    assert(NUMBER_EXISTS(story.author.userId));
    story.canContribute = story.canView = YES;
    
    story.remoteStatus = RemoteObjectStatusPushing;
    
    // Block to upload the story
    void (^createStory)(Story *) = ^(Story *story) {
        NSLog(@"Adding story %@", story);
        
        [[RKObjectManager sharedManager] postObject:story
                                               path:nil
                                         parameters:nil
                                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                NSLog(@"Create story successful %@", story);
                                                story.remoteStatus = RemoteObjectStatusSync;
                                                [Story viewedStory:story];
                                            }
                                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                story.remoteStatus = RemoteObjectStatusFailed;
                                                [story save];
                                                NSLog(@"Error in create story");
                                            }];
    };

    if ([story.media count]) {
        // Story should only have 1 media at most
        assert(story.media.count <= 1);
        
        // If all the media haven't been uploaded yet, don't edit the story
        BOOL mediaBeingUploaded = NO;
        for (Media *media in story.media) {
            if ([media.localURL length]) {
                assert(media.remoteStatus != MediaRemoteStatusSync);
                
                if (media.remoteStatus == MediaRemoteStatusProcessing || media.remoteStatus == MediaRemoteStatusPushing) {
                    mediaBeingUploaded = YES;
                    continue;
                }
                // Upload the media then create the story
                [media
                 uploadWithSuccess:^{
                     NSLog(@"Successfully uploaded %@ [%@] when creating story %@", media.mediaTypeName, media.filename, story.title);
                     story.remoteStatus = RemoteObjectStatusPushing; // So that the story can be uploaded now with all the media
                     [Story createNewStory:story];
                 }
                 failure:^(NSError *error) {
                     story.remoteStatus = RemoteObjectStatusFailed;
                     [story save];
                     NSLog(@"Error uploading %@ [%@] when creating story %@", media.mediaTypeName, media.filename, story.title);
                 }];
                mediaBeingUploaded = YES;
            }
        }
        // Media is being uploaded
        if (mediaBeingUploaded)
            return;
        
        // All the media has been uploaded. So the createStory can happen now
        createStory(story);
    }
    // No media changed.
    else {
        createStory(story);
    }
    
    // Save this story in the UserDefaults so that next time the user will add a piece here.
    [story saveStoryMOIdToUserDefaults];
    [story save];
}

@end

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
#import "AFBanyanAPIClient.h"
#import "UIImage+ResizeAdditions.h"
#import "Media.h"
#import "User.h"

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

    [story save];
    
    return story;
}

// Upload the given story using RestKit
+ (void)createNewStory:(Story *)story
{
    assert(story.bnObjectId.length == 0);
    assert(story.author.userId.length > 0);
    story.canContribute = story.canView = YES;
    
    story.remoteStatus = RemoteObjectStatusPushing;

    // Persist again
    [story save];
    
    NSLog(@"Adding story %@", story);


    //    PARSE
    void (^sendRequestToContributors)(Story *) = ^(Story *story) {
        NSArray *contributorsList = [story storyContributors];
        
        NSMutableArray *fbIds = [NSMutableArray arrayWithCapacity:1];
        for (NSDictionary *contributor in contributorsList)
        {
            if (![[contributor objectForKey:@"id"] isEqualToString:[[PFUser currentUser] objectForKey:USER_FACEBOOK_ID]])
                [fbIds addObject:[contributor objectForKey:@"id"]];
        }
        
        if ([fbIds count] == 0)
            return;
        
        // send request to facebook
        
        FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
        params.dataFailuresFatal = NO;
        params.caption = story.title;
        params.description = @"Check this new story out!";
        params.friends = fbIds;
        Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:story.media];
        params.picture = [NSURL URLWithString:imageMedia.remoteURL];
        params.ref = @"Story";
        [FBDialogs presentShareDialogWithParams:params clientState:nil handler:nil];
         
        // send push notifications
        
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if (types == UIRemoteNotificationTypeNone)
            return;
        
        for (NSString *fbId in fbIds)
        {
            // get the user object id corresponding to this facebook id if it exists
            NSDictionary *jsonDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            fbId, USER_FACEBOOK_ID, nil];
            
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
            
            if (!jsonData) {
                NSLog(@"NSJSONSerialization failed %@", error);
            }
            
            NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            NSMutableDictionary *getUsersForFbId = [NSMutableDictionary dictionaryWithObject:json forKey:@"where"];
            
            [[AFParseAPIClient sharedClient] getPath:PARSE_API_USER_URL(@"")
                                          parameters:getUsersForFbId
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSDictionary *response = responseObject;
                                                 NSArray *users = [response objectForKey:@"results"];
                                                 NSMutableArray *channels = [NSMutableArray arrayWithCapacity:1];
                                                 for (NSDictionary *user in users)
                                                 {
                                                     NSString *channel = [NSString stringWithFormat:@"%@%@%@", [user objectForKey:@"objectId"], BNPushNotificationChannelTypeSeperator, BNAddStoryInvitedContributePushNotification];
                                                     [channels addObject:channel];
                                                 }
                                                 NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                        [NSString stringWithFormat:@"%@ has invited you to contribute to a story titled %@",
                                                                        [[PFUser currentUser] objectForKey:USER_NAME], story.title], @"alert",
                                                                        [NSNumber numberWithInt:1], @"badge",
                                                                        story.bnObjectId, @"Story id",
                                                                        nil];
                                                 // send push notication to this user id
                                                 PFPush *push = [[PFPush alloc] init];
                                                 [push setChannels:channels];
                                                 [push setPushToAndroid:false];
                                                 [push expireAfterTimeInterval:86400];
                                                 [push setData:data];
                                                 [push sendPushInBackground];
                                                 [TestFlight passCheckpoint:@"Push notifications sent to contribute to a new story"];
                                             }
                                             failure:AF_PARSE_ERROR_BLOCK()];
        }
    };
    
    void (^sendRequestToViewers)(Story *) = ^(Story *story) {
        NSArray *viewersList = [story storyViewers];
        
        NSMutableArray *fbIds = [NSMutableArray arrayWithCapacity:1];
        for (NSDictionary *viewer in viewersList)
        {
            if (![[viewer objectForKey:@"id"] isEqualToString:[[PFUser currentUser] objectForKey:USER_FACEBOOK_ID]])
                [fbIds addObject:[viewer objectForKey:@"id"]];
        }
        
        if ([fbIds count] == 0)
            return;
        
        // send request to facebook
        
        FBShareDialogParams *params = [[FBShareDialogParams alloc] init];
        params.dataFailuresFatal = NO;
        params.caption = story.title;
        params.description = @"Check this new story out!";
        params.friends = fbIds;
        Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:story.media];
        params.picture = [NSURL URLWithString:imageMedia.remoteURL];
        params.ref = @"Story";
        [FBDialogs presentShareDialogWithParams:params clientState:nil handler:nil];
        
        // send push notifications
        
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if (types == UIRemoteNotificationTypeNone)
            return;
        
        for (NSString *fbId in fbIds)
        {
            // get the user object id corresponding to this facebook id if it exists
            NSDictionary *jsonDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            fbId, USER_FACEBOOK_ID, nil];
            
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
            
            if (!jsonData) {
                NSLog(@"NSJSONSerialization failed %@", error);
            }
            
            NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            NSMutableDictionary *getUsersForFbId = [NSMutableDictionary dictionaryWithObject:json forKey:@"where"];
            
            [[AFParseAPIClient sharedClient] getPath:PARSE_API_USER_URL(@"")
                                          parameters:getUsersForFbId
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSDictionary *response = responseObject;
                                                 NSArray *users = [response objectForKey:@"results"];
                                                 NSMutableArray *channels = [NSMutableArray arrayWithCapacity:1];
                                                 for (NSDictionary *user in users)
                                                 {
                                                     NSString *channel = [NSString stringWithFormat:@"%@%@%@", [user objectForKey:@"objectId"], BNPushNotificationChannelTypeSeperator, BNAddStoryInvitedViewPushNotification];
                                                     [channels addObject:channel];
                                                 }
                                                 NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                       [NSString stringWithFormat:@"%@ has invited you to view a story titled %@",
                                                                        [[PFUser currentUser] objectForKey:USER_NAME], story.title], @"alert",
                                                                       [NSNumber numberWithInt:1], @"badge",
                                                                       story.bnObjectId, @"Story id",
                                                                       nil];
                                                 // send push notication to this user id
                                                 PFPush *push = [[PFPush alloc] init];
                                                 [push setChannels:channels];
                                                 [push setPushToAndroid:false];
                                                 [push expireAfterTimeInterval:86400];
                                                 [push setData:data];
                                                 [push sendPushInBackground];
                                                 [TestFlight passCheckpoint:@"Push notifications sent to view a new story"];
                                             }
                                             failure:AF_PARSE_ERROR_BLOCK()];
        }
    };
    
    // Block to upload the story
    void (^uploadStory)(Story *) = ^(Story *story) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        objectManager.managedObjectStore = [RKManagedObjectStore defaultStore];

        // For serializing
        RKObjectMapping *storyRequestMapping = [RKObjectMapping requestMapping];
        [storyRequestMapping addAttributeMappingsFromArray:@[STORY_TITLE, STORY_WRITE_ACCESS, STORY_READ_ACCESS, STORY_TAGS, @"isLocationEnabled"]];
        [storyRequestMapping addAttributeMappingsFromDictionary:@{@"author.userId" : @"authorId"}];
        
        RKObjectMapping *locationMapping = [RKObjectMapping requestMapping];
        [locationMapping addAttributeMappingsFromArray:@[@"id", @"category", @"name"]];
        RKObjectMapping *locationLocationMapping = [RKObjectMapping requestMapping];
        [locationLocationMapping addAttributeMappingsFromArray:@[@"street", @"city", @"state", @"country", @"zip", @"latitude", @"longitude"]];
        [locationMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationLocationMapping]];
        [storyRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationMapping]];
        
        RKObjectMapping *mediaMapping = [RKObjectMapping requestMapping];
        [mediaMapping addAttributeMappingsFromDictionary:@{@"remoteURL": @"url"}];
        [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType"]];
        [storyRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media" toKeyPath:@"media" withMapping:mediaMapping]];
        
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                                  requestDescriptorWithMapping:storyRequestMapping
                                                  objectClass:[Story class]
                                                  rootKeyPath:nil];
        RKEntityMapping *storyResponseMapping = [RKEntityMapping mappingForEntityForName:kBNStoryClassKey
                                                                    inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [storyResponseMapping addAttributeMappingsFromDictionary:@{
                                                PARSE_OBJECT_ID : @"bnObjectId",
         }];
        [storyResponseMapping addAttributeMappingsFromArray:@[PARSE_OBJECT_CREATED_AT, PARSE_OBJECT_UPDATED_AT]];
        storyResponseMapping.identificationAttributes = @[@"bnObjectId"];

        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:storyResponseMapping
                                                                                           pathPattern:nil
                                                                                               keyPath:nil
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addRequestDescriptor:requestDescriptor];
        [objectManager addResponseDescriptor:responseDescriptor];
        
        [objectManager postObject:story
                             path:BANYAN_API_CLASS_URL(kBNStoryClassKey)
                       parameters:nil
                          success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              NSLog(@"Create story successful %@", story);
                              story.remoteStatus = RemoteObjectStatusSync;
                              if ([story numberOfContributors]) {
                                  sendRequestToContributors(story);
                              }
                              if ([story numberOfViewers]) {
                                  sendRequestToViewers(story);
                              }
                              [story save];
                          }
                          failure:^(RKObjectRequestOperation *operation, NSError *error) {
                              story.remoteStatus = RemoteObjectStatusFailed;
                              [story save];
                              NSLog(@"Error in create story");
                          }];
    };
    
    // Upload the file and then upload the story
    if ([story.media count]) {
        BOOL mediaBeingUploaded = NO;
        for (Media *media in story.media) {
            if ([media.localURL length]) {
                // Upload the media then update the story
                [media
                 uploadWithSuccess:^{
                     uploadStory(story);
                 }
                 failure:^(NSError *error) {
                     story.remoteStatus = RemoteObjectStatusFailed;
                     [story save];
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in finding Image"
                                                                     message:[NSString stringWithFormat:@"Can't find Asset Library image. Error: %@", error.localizedDescription]
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
                     [alert show];
                 }];
                mediaBeingUploaded = YES;
            }
        }
        // Media wasn't changed.
        if (!mediaBeingUploaded) {
            uploadStory(story);
        }
    }
    // No media
    else {
        uploadStory(story);
    }
}

@end

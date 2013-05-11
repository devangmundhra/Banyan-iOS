//
//  Story+Create.m
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Create.h"
#import "Story_Defines.h"
#import "User_Defines.h"
#import "BanyanDataSource.h"
#import "AFBanyanAPIClient.h"
#import "UIImage+ResizeAdditions.h"
#import "Media.h"

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
    story.author = [User userForPfUser:[PFUser currentUser]];
    story.createdAt = story.updatedAt = [NSDate date];

    [story save];
    
    return story;
}

// Upload the given story using RestKit
+ (Story *)createNewStory:(Story *)story
{    
    story.canContribute = story.canView = [NSNumber numberWithBool:YES];
    
    // Persist again
    [story save];
    NSLog(@"Adding story %@", story);

    //    PARSE
    void (^sendRequestToContributors)(NSArray *, Story *) = ^(NSArray *contributorsList, Story *story) {
        NSMutableArray *fbIds = [NSMutableArray arrayWithCapacity:1];
        for (NSDictionary *contributor in contributorsList)
        {
            if (![[contributor objectForKey:@"id"] isEqualToString:[[PFUser currentUser] objectForKey:USER_FACEBOOK_ID]])
                [fbIds addObject:[contributor objectForKey:@"id"]];
        }
        
        if ([fbIds count] == 0)
            return;
        
        // send request to facebook
        /*
         NSString *selectIDsStr = [fbIds componentsJoinedByString:@","];
         NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"Check this story", @"message", selectIDsStr, @"to", nil];
         [[PFFacebookUtils facebook] dialog:@"apprequests"
         andParams:params
         andDelegate:story];
         */
        // send push notifications
        
        //        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        //        if (types == UIRemoteNotificationTypeNone)
        //            return;
        
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
                                                 NSMutableArray *usersContributing = [NSMutableArray arrayWithCapacity:1];
                                                 for (NSDictionary *user in users)
                                                 {
                                                     [usersContributing addObject:[user objectForKey:@"objectId"]];
                                                 }
                                                 NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                        [NSString stringWithFormat:@"%@ has invited you to contribute to a story titled %@",
                                                                        [[PFUser currentUser] objectForKey:USER_NAME], story.title], @"alert",
                                                                        [NSNumber numberWithInt:1], @"badge",
                                                                        story.title, @"Story title",
                                                                        nil];
                                                 // send push notication to this user id
                                                 PFPush *push = [[PFPush alloc] init];
                                                 [push setChannels:usersContributing];
                                                 [push setPushToAndroid:false];
                                                 [push expireAfterTimeInterval:86400];
                                                 [push setData:data];
                                                 [push sendPushInBackground];
                                                 [TestFlight passCheckpoint:@"Push notifications sent to contribute to a new story"];
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
        
        story.remoteStatus = RemoteObjectStatusPushing;
        [objectManager postObject:story
                             path:BANYAN_API_CLASS_URL(kBNStoryClassKey)
                       parameters:nil
                          success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              NSLog(@"Create story successful %@", story);
                              story.remoteStatus = RemoteObjectStatusSync;
                              NSArray *invitedFBFriends = [[story.writeAccess objectForKey:kBNStoryPrivacyInviteeList]
                                                           objectForKey:kBNStoryPrivacyInvitedFacebookFriends];
                              if (invitedFBFriends) {
                                  sendRequestToContributors(invitedFBFriends, story);
                              }
                              [story save];
                          }
                          failure:^(RKObjectRequestOperation *operation, NSError *error) {
                              story.remoteStatus = RemoteObjectStatusFailed;
                              NSLog(@"Error in create story");
                          }];
    };
    
    // Upload the file and then upload the story
    if ([story.media.localURL length]) {
        [story.media uploadWithSuccess:^{
            uploadStory(story);
            NSLog(@"Image saved on server");
        }
                               failure:^(NSError *error) {
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in finding Image"
                                                                                   message:[NSString stringWithFormat:@"Can't find Asset Library image. Error: %@", error.localizedDescription]
                                                                                  delegate:nil
                                                                         cancelButtonTitle:@"OK"
                                                                         otherButtonTitles:nil];
                                   [alert show];
        }];
    } else {
        uploadStory(story);
    }
    
    return story;
}

@end

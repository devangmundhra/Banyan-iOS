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
#import "User+Edit.h"

@implementation Story (Create)

// Upload the given story using RestKit
+ (void)createNewStory:(Story *)story
{
    story.initialized = [NSNumber numberWithBool:NO];
    story.canContribute = story.canView = [NSNumber numberWithBool:YES];
    story.author = [User currentUser];
    story.storyBeingRead = [NSNumber numberWithBool:YES];
    story.createdAt = story.updatedAt = [NSDate date];
    
    NSLog(@"Adding story %@", story);

    //    PARSE
    void (^sendRequestToContributors)(NSArray *, Story *) = ^(NSArray *contributorsList, Story *story) {
        NSMutableArray *fbIds = [NSMutableArray arrayWithCapacity:1];
        for (NSDictionary *contributor in contributorsList)
        {
            if (![[contributor objectForKey:@"id"] isEqualToString:[User currentUser].facebookId])
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
                                                                        story.author.name, story.title], @"alert",
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
        
        [storyRequestMapping addAttributeMappingsFromArray:@[STORY_TITLE, STORY_IMAGE_URL, STORY_WRITE_ACCESS, STORY_READ_ACCESS,
                                                            STORY_LATITUDE, STORY_LONGITUDE, STORY_GEOCODEDLOCATION, STORY_TAGS]];
        [storyRequestMapping addAttributeMappingsFromDictionary:@{@"author.userId" : STORY_AUTHOR}];
        
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                                  requestDescriptorWithMapping:storyRequestMapping
                                                  objectClass:[Story class]
                                                  rootKeyPath:nil];
        RKEntityMapping *storyResponseMapping = [RKEntityMapping mappingForEntityForName:kBNStoryClassKey
                                                                    inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [storyResponseMapping addAttributeMappingsFromDictionary:@{
                                                PARSE_OBJECT_ID : @"storyId",
         }];
        [storyResponseMapping addAttributeMappingsFromArray:@[PARSE_OBJECT_CREATED_AT, PARSE_OBJECT_UPDATED_AT]];
        storyResponseMapping.identificationAttributes = @[@"storyId"];

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
                              story.initialized = [NSNumber numberWithBool:YES];
                              NSArray *invitedFBFriends = [[story.writeAccess objectForKey:kBNStoryPrivacyInviteeList]
                                                           objectForKey:kBNStoryPrivacyInvitedFacebookFriends];
                              if (invitedFBFriends) {
                                  sendRequestToContributors(invitedFBFriends, story);
                              }
                              [story persistToDatabase];
                          }
                          failure:^(RKObjectRequestOperation *operation, NSError *error) {
                              NSLog(@"Error in create story");
                          }];
    };
    
    // Upload the file and then upload the story
    if (story.imageURL) {
        [File uploadFileForLocalURL:story.imageURL
                              block:^(BOOL succeeded, NSString *newURL, NSString *newName, NSError *error) {
                                  if (succeeded) {
                                      story.imageURL = newURL;
                                      story.imageName = newName;
                                      uploadStory(story);
                                      NSLog(@"Image saved on server");
                                  } else {
                                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in uploading image"
                                                                                      message:[NSString stringWithFormat:@"Can't upload the image due to error %@", error.localizedDescription]
                                                                                     delegate:nil
                                                                            cancelButtonTitle:@"OK"
                                                                            otherButtonTitles:nil];
                                      [alert show];
                                  }
                              }
                         errorBlock:^(NSError *error) {
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
    
    [story persistToDatabase];
}

- (void)persistToDatabase
{
    [self.managedObjectContext performBlockAndWait:^{
        // Persist the story
        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error: %@", error);
            assert(false);
        };
    }];
    
    // Fetch the object in NSFetchedResultsController's context
    [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext objectWithID:self.objectID];
    
//    [self.managedObjectContext.parentContext performBlockAndWait:^{
//        // Persist the story on the parent context so that it is picked up by Fetched Results Controller
//        NSError *error = nil;
//        if (![self.managedObjectContext save:&error]) {
//            NSLog(@"Error: %@", error);
//            assert(false);
//        };
//    }];
}

@end

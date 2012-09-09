//
//  Story+Create.m
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Create.h"
#import "Story_Defines.h"
#import "StoryDocuments.h"
#import "Scene_Defines.h"
#import "User_Defines.h"
#import "BanyanDataSource.h"

@implementation Story (Create)

//Create a story here with the given attributes.
//Get a unique id and create the story with using the attributes
//in 'attribute' and the unique id created

+ (void) cleanUpStoryAttributes:(NSMutableDictionary *)attributes
{    
    if ([[attributes objectForKey:STORY_PUBLIC_CONTRIBUTORS] isEqualToNumber:[NSNumber numberWithBool:NO]]) {
        [attributes setObject:[attributes objectForKey:STORY_INVITED_TO_CONTRIBUTE] forKey:STORY_INVITED_TO_CONTRIBUTE];
        [attributes setObject:[NSNumber numberWithBool:NO] forKey:STORY_PUBLIC_CONTRIBUTORS];
    }
    else {
        [attributes setObject:[NSNull null] forKey:STORY_INVITED_TO_CONTRIBUTE];
        [attributes setObject:[NSNumber numberWithBool:YES] forKey:STORY_PUBLIC_CONTRIBUTORS];
    }
    
    if ([[attributes objectForKey:STORY_PUBLIC_VIEWERS] isEqualToNumber:[NSNumber numberWithBool:NO]]) {
        [attributes setObject:[attributes objectForKey:STORY_INVITED_TO_VIEW] forKey:STORY_INVITED_TO_VIEW];
        [attributes setObject:[NSNumber numberWithBool:NO] forKey:STORY_PUBLIC_VIEWERS];
    }
    else {
        [attributes setObject:[NSNull null] forKey:STORY_INVITED_TO_VIEW];
        [attributes setObject:[NSNumber numberWithBool:YES] forKey:STORY_PUBLIC_VIEWERS];
    }
    
    [attributes setObject:[NSNumber numberWithInt:0] forKey:STORY_NUM_LIKES];
    [attributes setObject:[NSNumber numberWithInt:0] forKey:STORY_NUM_VIEWS];
    [attributes setObject:[NSNumber numberWithInt:0] forKey:STORY_NUM_CONTRIBUTORS];
    
    [attributes setObject:[NSNumber numberWithInt:0] forKey:STORY_LENGTH];
}

+ (Story *)createStoryWithAttributes:(NSMutableDictionary *)attributes
{
    NSLog(@"Adding story with attributes %@", attributes);
    
    [Story cleanUpStoryAttributes:attributes];
    
    Story *story = [Story createStoryOnDiskWithAttributes:attributes];    
    
//    [Story createStoryOnNetworkWithAttributes:attributes forStory:story];
    NSLog(@"Done adding story with title %@", story.title);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:STORY_NEW_STORY_NOTIFICATION
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObject:story 
                                                                                           forKey:@"Story"]];
    
    NSMutableDictionary *sceneParams = [NSMutableDictionary dictionaryWithCapacity:1];
    if (![story.title isEqual:[NSNull null]] && story.title)
        [sceneParams setObject:story.title forKey:SCENE_TEXT];
    if (![story.image isEqual:[NSNull null]] && story.image)
        [sceneParams setObject:story.image forKey:SCENE_IMAGE];
    if (story.isLocationEnabled) {
        CLLocationCoordinate2D coord = [story.location coordinate];
        [sceneParams setObject:[NSNumber numberWithDouble:coord.latitude]
                       forKey:SCENE_LATITUDE];
        [sceneParams setObject:[NSNumber numberWithDouble:coord.longitude]
                       forKey:SCENE_LONGITUDE];
        [sceneParams setObject:story.geocodedLocation
                        forKey:SCENE_GEOCODEDLOCATION];
    }
    
    [Scene createSceneForStory:story attributes:sceneParams afterScene:nil];
    
    // Creating the network operations snippet for offline support
    BNOperationObject *obj = [[BNOperationObject alloc] 
                                         initWithObjectType:BNOperationObjectTypeStory 
                                         tempId:story.storyId 
                                         storyId:story.storyId];
    
    BNOperation *operation = [[BNOperation alloc] 
                                         initWithObject:obj
                                         action:BNOperationActionCreate 
                                         dependencies:nil];
    
    if (!story.startingScene.initialized) {
        BNOperationDependency *dObj = [[BNOperationDependency alloc]
                                       initWithObjectType:BNOperationObjectTypeScene
                                       tempId:story.startingScene.sceneId
                                       storyId:story.startingScene.story.storyId
                                       field:STORY_STARTING_SCENE];
        
        [operation addDependencyObject:dObj];
    }
    
    [[BNOperationQueue shared] addOperation:operation];
    
    [StoryDocuments saveStoryToDisk:story];

    return story;
}

+ (Story *)createStoryOnDiskWithAttributes:(NSMutableDictionary *)attributes
{
    Story *story = [[Story alloc] init];
    NSString *tempId = [NSString stringWithFormat:@"temp%@", [[NSProcessInfo processInfo] globallyUniqueString]];
    
    // DISK
    story.storyId = tempId;
    story.initialized = NO;
    
    story.title = [attributes objectForKey:STORY_TITLE];
    if (![[attributes objectForKey:STORY_IMAGE] isEqual:[NSNull null]])
        story.image = [attributes objectForKey:STORY_IMAGE];
    story.canView = YES;
    story.canContribute = YES;
    
    if ([[attributes objectForKey:STORY_PUBLIC_CONTRIBUTORS] isEqualToNumber:[NSNumber numberWithBool:YES]]) 
        story.publicContributors = YES;
    else
    {
        story.isInvited = YES;
        story.publicContributors = NO;
        NSArray *invited = [attributes objectForKey:STORY_INVITED_TO_CONTRIBUTE];
        story.invitedToContribute = invited;
    }
    
    if ([[attributes objectForKey:STORY_PUBLIC_VIEWERS] isEqualToNumber:[NSNumber numberWithBool:YES]]) 
        story.publicViewers = YES;
    else
    {
        story.isInvited = YES;
        story.publicViewers = NO;
        NSArray *invited = [attributes objectForKey:STORY_INVITED_TO_VIEW];
        story.invitedToView = invited;
    }
    
    if ([[attributes objectForKey:STORY_LOCATION_ENABLED] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        story.isLocationEnabled = YES;
        double latitude = [[attributes objectForKey:STORY_LATITUDE] doubleValue];
        double longitude = [[attributes objectForKey:STORY_LONGITUDE] doubleValue];
        story.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        story.geocodedLocation = [attributes objectForKey:STORY_GEOCODEDLOCATION];
    }
    else
    {
        story.isLocationEnabled = NO;
    }
    story.author = [User currentUser];
    story.storyBeingRead = YES;
    story.numberOfContributors = [NSNumber numberWithInt:0];
    story.numberOfLikes = [NSNumber numberWithInt:0];
    story.numberOfViews = [NSNumber numberWithInt:0];

    return story;
}

+ (void) createStoryOnServer:(Story *)story
{
    assert(story);
    NSLog(@"%s story: %@", __PRETTY_FUNCTION__, story);
    NSMutableDictionary *attributes = [story getAttributesInDictionary];
    
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
                                                                        [User currentUser].name, story.title], @"alert",
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
                                                 NETWORK_OPERATION_COMPLETE();
                                             }
                                             failure:BN_ERROR_BLOCK_OPERATION_COMPLETE()];
        }
    };
    
    [[AFParseAPIClient sharedClient] postPath:PARSE_API_CLASS_URL(@"Story")
                                   parameters:attributes
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *response = responseObject;
                                          NSLog(@"Got response for creating story %@", [response objectForKey:@"objectId"]);
                                          NSString *newId = [response objectForKey:@"objectId"];
                                          [StoryDocuments deleteStoryFromDisk:story];
                                          [[BanyanDataSource hashTable] setObject:newId forKey:story.storyId];
                                          [BanyanDataSource archiveHashTable];
                                          story.storyId = newId;
                                          
                                          story.initialized = YES;
                                          [StoryDocuments saveStoryToDisk:story];
                                          if (story.invitedToContribute) {
                                              sendRequestToContributors(story.invitedToContribute, story);
                                          }
                                          NETWORK_OPERATION_COMPLETE();
                                      }
                                      failure:BN_ERROR_BLOCK_OPERATION_INCOMPLETE()];
}

# pragma mark PF_FBDialogDelegate

- (void)dialog:(PF_FBDialog *)dialog didFailWithError:(NSError *)error
{
    NSLog(@"%s FB dialog", __PRETTY_FUNCTION__);
}

- (void) dialogCompleteWithUrl:(NSURL *)url
{
    NSLog(@"%s FB dialog", __PRETTY_FUNCTION__);    
}

- (void)dialogDidComplete:(PF_FBDialog *)dialog
{
    NSLog(@"%s FB dialog", __PRETTY_FUNCTION__);
}

- (void)dialogDidNotComplete:(PF_FBDialog *)dialog
{
    NSLog(@"%s FB dialog", __PRETTY_FUNCTION__);
}

- (void)dialogDidNotCompleteWithUrl:(NSURL *)url
{
    NSLog(@"%s FB dialog", __PRETTY_FUNCTION__);
}

@end

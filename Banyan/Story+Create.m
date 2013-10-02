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

    // Block to upload the story
    void (^uploadStory)(Story *) = ^(Story *story) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        objectManager.managedObjectStore = [RKManagedObjectStore defaultStore];
        
        // For serializing
        RKObjectMapping *storyRequestMapping = [RKObjectMapping requestMapping];
        [storyRequestMapping addAttributeMappingsFromArray:@[STORY_TITLE, STORY_WRITE_ACCESS, STORY_READ_ACCESS, STORY_TAGS, @"isLocationEnabled", @"timeStamp"]];
        [storyRequestMapping addAttributeMappingsFromDictionary:@{@"author.resourceUri" : @"author"}];
        
        RKObjectMapping *locationMapping = [RKObjectMapping requestMapping];
        [locationMapping addAttributeMappingsFromArray:@[@"id", @"category", @"name"]];
        RKObjectMapping *locationLocationMapping = [RKObjectMapping requestMapping];
        [locationLocationMapping addAttributeMappingsFromArray:@[@"street", @"city", @"state", @"country", @"zip", @"latitude", @"longitude"]];
        [locationMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationLocationMapping]];
        [storyRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationMapping]];
        
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                                  requestDescriptorWithMapping:storyRequestMapping
                                                  objectClass:[Story class]
                                                  rootKeyPath:nil
                                                  method:RKRequestMethodPOST];
        
        RKEntityMapping *storyResponseMapping = [RKEntityMapping mappingForEntityForName:kBNStoryClassKey
                                                                    inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [storyResponseMapping addAttributeMappingsFromDictionary:@{@"resource_uri": @"resourceUri"}];
        [storyResponseMapping addAttributeMappingsFromArray:@[@"createdAt", @"updatedAt", @"permaLink", @"bnObjectId"]];
        storyResponseMapping.identificationAttributes = @[@"bnObjectId"];
        
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:storyResponseMapping
                                                                                                method:RKRequestMethodPOST
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
    };
    
    uploadStory(story);

    // Save this story in the UserDefaults so that next time the user will add a piece here.
    [story saveStoryMOIdToUserDefaults];
}

@end

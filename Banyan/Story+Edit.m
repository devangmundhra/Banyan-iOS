//
//  Story+Edit.m
//  Storied
//
//  Created by Devang Mundhra on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Edit.h"
#import "AFParseAPIClient.h"

@implementation Story (Edit)

+ (void) editStory:(Story *)story
{
    if (!story.initialized)
        return;
    
     NSLog(@"Edit Story %@", story);
    [[NSNotificationCenter defaultCenter] postNotificationName:STORY_EDIT_STORY_NOTIFICATION
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObject:story 
                                                                                           forKey:@"Story"]];
    
    // Block to upload the story
    void (^updateStory)(Story *) = ^(Story *story) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFParseAPIClient sharedClient]];
        // For serializing
        RKObjectMapping *storyRequestMapping = [RKObjectMapping requestMapping];
        [storyRequestMapping addAttributeMappingsFromArray:@[STORY_TITLE, STORY_IMAGE_URL, STORY_IMAGE_NAME, STORY_WRITE_ACCESS, STORY_READ_ACCESS,
         STORY_LATITUDE, STORY_LONGITUDE, STORY_GEOCODEDLOCATION, STORY_TAGS]];
        
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                                  requestDescriptorWithMapping:storyRequestMapping
                                                  objectClass:[Story class]
                                                  rootKeyPath:nil];
        RKObjectMapping *storyResponseMapping = [RKObjectMapping mappingForClass:[Story class]];

        [storyResponseMapping addAttributeMappingsFromArray:@[PARSE_OBJECT_UPDATED_AT]];
        
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:storyResponseMapping
                                                                                           pathPattern:nil
                                                                                               keyPath:nil
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addRequestDescriptor:requestDescriptor];
        [objectManager addResponseDescriptor:responseDescriptor];
        
        [objectManager postObject:story
                             path:PARSE_API_OBJECT_URL(@"Story", story.storyId)
                       parameters:nil
                          success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              NSLog(@"Update story successful %@", story);
                              [[BanyanDataSource shared] addObject:story];
                          }
                          failure:^(RKObjectRequestOperation *operation, NSError *error) {
                              NSLog(@"Error in create story");
                          }];
    };
    
    if (story.imageChanged)
    {
        story.imageChanged = NO;
        // Upload the image then update the story
        if (story.imageURL)
        {
            [File uploadFileForLocalURL:story.imageURL
                                  block:^(BOOL succeeded, NSString *newURL, NSString *newName, NSError *error) {
                                      if (succeeded) {
                                          story.imageURL = newURL;
                                          story.imageName = newName;
                                          updateStory(story);
                                          NSLog(@"Image updated on server");
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
            // Delete the file from db and update the story
            [File deleteFileWithName:story.imageName
                               block:nil
                          errorBlock:^(NSError *error) {
                              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in finding Image"
                                                                              message:[NSString stringWithFormat:@"Can't find Asset Library image. Error: %@", error.localizedDescription]
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
                              [alert show];
                          }];
            story.imageName = nil;
            updateStory(story);
        }
    } else {
        updateStory(story);
    }
}

@end

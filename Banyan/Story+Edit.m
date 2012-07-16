//
//  Story+Edit.m
//  Storied
//
//  Created by Devang Mundhra on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Edit.h"
#import "Story_Defines.h"
#import "StoryDocuments.h"

@implementation Story (Edit)

+ (void) editStory:(Story *)story
{
    if (![[ParseAPIEngine sharedEngine] isReachable]) {
        NSLog(@"%s Can't connect to internet", __PRETTY_FUNCTION__);
        [ParseAPIEngine showNetworkUnavailableAlert];
        return;
    }
    
     NSLog(@"Edit Story %@", story);
    [[NSNotificationCenter defaultCenter] postNotificationName:STORY_EDIT_STORY_NOTIFICATION
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObject:story 
                                                                                           forKey:@"Story"]];

    NSMutableDictionary *storyParams = [NSMutableDictionary dictionaryWithCapacity:1];
    // Maybe delete the image that was stored previously if another image has
    // come in
    PFFile *imageFile = nil;
    if (story.image)
    {
        NSData *imageData = UIImagePNGRepresentation(story.image);
        imageFile = [PFFile fileWithName:[story.storyId stringByAppendingString:@".png"] data:imageData];
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                story.imageURL = imageFile.url;
                
                MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Story", story.storyId) 
                                                                                   params:[NSMutableDictionary dictionaryWithObject:imageFile.url 
                                                                                                                             forKey:STORY_IMAGE_URL] 
                                                                               httpMethod:@"PUT" 
                                                                                      ssl:YES];
                [op
                 onCompletion:^(MKNetworkOperation *completedOperation) {
                     NSLog(@"Updating story with imageURL %@", imageFile.url);
                 } 
                 onError:PARSE_ERROR_BLOCK()];
                
                [[ParseAPIEngine sharedEngine] enqueueOperation:op];
            }
            else {
                NSLog(@"%s Error %@: Can't save image for story", __PRETTY_FUNCTION__, error);
            }
        }];
    }
    
    // Update the story
    [storyParams setObject:story.title forKey:STORY_TITLE];
    [storyParams setObject:[NSNumber numberWithBool:story.publicContributors] forKey:STORY_PUBLIC_CONTRIBUTORS];
    if (!story.publicContributors)
        [storyParams setObject:story.invitedToContribute forKey:STORY_INVITED_TO_CONTRIBUTE];
    else
        [storyParams setObject:[NSNull null] forKey:STORY_INVITED_TO_CONTRIBUTE];
    
    [storyParams setObject:[NSNumber numberWithBool:story.publicViewers] forKey:STORY_PUBLIC_VIEWERS];
    if (!story.publicViewers)
        [storyParams setObject:story.invitedToView forKey:STORY_INVITED_TO_VIEW];
    else
        [storyParams setObject:[NSNull null] forKey:STORY_INVITED_TO_VIEW];
    
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Story", story.storyId) 
                                                                       params:storyParams
                                                                   httpMethod:@"PUT" 
                                                                          ssl:YES];
    [op
     onCompletion:^(MKNetworkOperation *completedOperation) {
         NSDictionary *response = [completedOperation responseJSON];
         NSLog(@"Got response for updating story parameters at %@", [response objectForKey:@"updatedAt"]);
     } 
     onError:PARSE_ERROR_BLOCK()];
    
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];

    [StoryDocuments saveStoryToDisk:story];
}

- (void)startingSceneForStory:(Scene *)scene
{
    if (![[ParseAPIEngine sharedEngine] isReachable]) {
        NSLog(@"%s Can't connect to internet", __PRETTY_FUNCTION__);
        [ParseAPIEngine showNetworkUnavailableAlert];
        return;
    }
    
    NSMutableDictionary *storyEditParams = [NSMutableDictionary dictionaryWithCapacity:1];
    [storyEditParams setObject:scene.sceneId forKey:STORY_STARTING_SCENE];
    
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Story", self.storyId) 
                                                                       params:storyEditParams
                                                                   httpMethod:@"PUT" 
                                                                          ssl:YES];
    [op
     onCompletion:^(MKNetworkOperation *completedOperation) {
         NSDictionary *response = [completedOperation responseJSON];
         NSLog(@"Got response for updating story with starting scene at %@", [response objectForKey:@"updatedAt"]);
     } 
     onError:PARSE_ERROR_BLOCK()];
    
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
}

- (void)incrementStoryAttribute:(NSString *)attribute byAmount:(NSNumber *)inc
{
    NSMutableDictionary *storyEditParams = [NSMutableDictionary dictionaryWithCapacity:1];
    
    NSDictionary *storyAttrInc = [NSDictionary dictionaryWithObjectsAndKeys:@"Increment", @"__op", 
                                    inc, @"amount", nil];
    [storyEditParams setObject:storyAttrInc forKey:attribute];
    
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Story", self.storyId) 
                                                                       params:storyEditParams
                                                                   httpMethod:@"PUT" 
                                                                          ssl:YES];
    [op
     onCompletion:^(MKNetworkOperation *completedOperation) {
         NSDictionary *response = [completedOperation responseJSON];
         NSLog(@"Got response for updating story attr %@ at %@", attribute, [response objectForKey:@"updatedAt"]);
     } 
     onError:PARSE_ERROR_BLOCK()];
    
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
}

@end

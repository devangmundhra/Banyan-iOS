//
//  Story+Edit.m
//  Storied
//
//  Created by Devang Mundhra on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Edit.h"
#import "StoryDocuments.h"
#import "ParseAPIEngine.h"

@implementation Story (Edit)

+ (void) editStory:(Story *)story
{
     NSLog(@"Edit Story %@", story);
    [[NSNotificationCenter defaultCenter] postNotificationName:STORY_EDIT_STORY_NOTIFICATION
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObject:story 
                                                                                           forKey:@"Story"]];

    NSMutableDictionary *storyParams = [NSMutableDictionary dictionaryWithCapacity:1];
    BNOperationDependency *imageDependency = nil;
    
    if (story.imageChanged)
    {
        story.imageChanged = NO;
        // Maybe delete the image that was stored previously if another image has
        // come in
        
        if (story.imageURL)
        {
            // Upload the image (ie, create a network request for that)
            BNOperationObject *imgObj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeFile
                                                                               tempId:story.imageURL
                                                                              storyId:nil];
            BNOperation *operation = [[BNOperation alloc] initWithObject:imgObj action:BNOperationActionCreate dependencies:nil];
            ADD_OPERATION_TO_QUEUE(operation);
            
            // Create a dependency object
            imageDependency = [[BNOperationDependency alloc] initWithBNObject:imgObj
                                                                        field:STORY_IMAGE_URL];
        } else {
            // Scene image was deleted
            [storyParams setObject:[NSNull null] forKey:STORY_IMAGE_URL];
        }
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
    
    BNOperationObject *obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeStory tempId:story.storyId storyId:story.storyId];
    BNOperation *operation = [[BNOperation alloc] initWithObject:obj action:BNOperationActionEdit dependencies:nil];
    operation.action.context = storyParams;
    if (imageDependency) {
        [operation addDependencyObject:imageDependency];
    }
    ADD_OPERATION_TO_QUEUE(operation);

    [StoryDocuments saveStoryToDisk:story];
}

+ (void) editStory:(Story *)story withAttributes:(NSMutableDictionary *)storyParams
{
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Story", story.storyId)
                                                                       params:storyParams
                                                                   httpMethod:@"PUT"
                                                                          ssl:YES];
    [op
     onCompletion:^(MKNetworkOperation *completedOperation) {
         NSDictionary *response = [completedOperation responseJSON];
         NSLog(@"Got response for updating story parameters %@ at %@", storyParams, [response objectForKey:@"updatedAt"]);
         NETWORK_OPERATION_COMPLETE();
     }
     onError:BN_ERROR_BLOCK_OPERATION_COMPLETE()];
    
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
    
    [StoryDocuments saveStoryToDisk:story];
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
         NETWORK_OPERATION_COMPLETE();
     } 
     onError:BN_ERROR_BLOCK_OPERATION_COMPLETE()];
    
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
}

@end

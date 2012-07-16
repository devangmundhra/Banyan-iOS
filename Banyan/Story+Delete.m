//
//  Story+Delete.m
//  Storied
//
//  Created by Devang Mundhra on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Delete.h"
#import "Story_Defines.h"
#import "Scene_Defines.h"
#import "ParseConnection.h"
#import "StoryDocuments.h"
#import "Scene+Delete.h"

@implementation Story (Delete)

+ (void) removeStory:(Story *)story
{
    NSLog(@"Remove Story %@", story);
    [[NSNotificationCenter defaultCenter] postNotificationName:STORY_DELETE_STORY_NOTIFICATION
                                                        object:self 
                                                      userInfo:[NSDictionary dictionaryWithObject:story 
                                                                                           forKey:@"Story"]];

    NSDictionary *jsonDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    story.storyId, SCENE_STORY, nil];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    if (!jsonData) {
        NSLog(@"NSJSONSerialization failed %@", error);
    }
    
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *getScenesForStory = [NSMutableDictionary dictionaryWithObject:json forKey:@"where"];
    
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_CLASS_URL(@"Scene") 
                                                                       params:getScenesForStory 
                                                                   httpMethod:@"GET" 
                                                                          ssl:YES];
    [op 
     onCompletion:^(MKNetworkOperation *completedOperation) {
         NSDictionary *response = [completedOperation responseJSON];
         NSArray *scenes = [response objectForKey:@"results"];
         for (NSDictionary *scene in scenes)
         {
             [Scene removeSceneWithId:[scene objectForKey:@"objectId"]];
         }
     } 
     onError:PARSE_ERROR_BLOCK()];
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];

    // Delete Object
    if (story.image || story.imageURL)
    {
        NSLog(@"Story Image still needs to be deleted");
    }
    
    [Story removeStoryWithId:story.storyId];

    // ARCHIVES
    
    [StoryDocuments deleteStoryFromDisk:story];
    NSLog(@"%s Deleted story %@", __PRETTY_FUNCTION__, story);
    story = nil;
}

+ (void) removeStoryWithId:(NSString *)storyId
{    
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Story", storyId) 
                                                                       params:nil 
                                                                   httpMethod:@"DELETE" 
                                                                          ssl:YES];
    [op 
     onCompletion:^(MKNetworkOperation *completedOperation) {
         NSLog(@"Story with id %@ deleted", storyId);
     } 
     onError:PARSE_ERROR_BLOCK()];
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
}
@end
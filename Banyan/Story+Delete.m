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
    
    [[AFParseAPIClient sharedClient] getPath:PARSE_API_CLASS_URL(@"Scene")
                                  parameters:getScenesForStory
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSDictionary *response = responseObject;
                                         NSArray *scenes = [response objectForKey:@"results"];
                                         for (NSDictionary *scene in scenes)
                                         {
                                             [Scene removeSceneWithId:[scene objectForKey:@"objectId"]];
                                         }
                                         
                                     }
                                     failure:BN_ERROR_BLOCK_OPERATION_COMPLETE()];

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
    [[AFParseAPIClient sharedClient] deletePath:PARSE_API_OBJECT_URL(@"Story", storyId)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            NSLog(@"Story with id %@ deleted", storyId);
                                        }
                                        failure:BN_ERROR_BLOCK_OPERATION_COMPLETE()];
}
@end
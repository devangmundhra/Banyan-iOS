//
//  Story+Delete.m
//  Storied
//
//  Created by Devang Mundhra on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Delete.h"
#import "Story_Defines.h"
#import "StoryDocuments.h"
#import "Scene+Delete.h"

@implementation Story (Delete)

+ (void) deleteStoryFromDisk:(Story *)story
{
    NSLog(@"%s Story id: %@", __PRETTY_FUNCTION__, story.storyId);
    [[NSNotificationCenter defaultCenter] postNotificationName:STORY_DELETE_STORY_NOTIFICATION
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:story
                                                                                           forKey:@"Story"]];
    
    // Delete Object
    if (story.imageURL)
    {
        NSLog(@"Story Image still needs to be deleted");
    }
    
    [StoryDocuments deleteStoryFromDisk:story];
    story = nil;
}

+ (void) deleteStoryFromServerWithId:(NSString *)storyId
{
    NSLog(@"%s Story id: %@", __PRETTY_FUNCTION__, storyId);

    NSDictionary *jsonDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    storyId, PIECE_STORY, nil];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    if (!jsonData) {
        NSLog(@"NSJSONSerialization failed %@", error);
    }
    
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *getScenesForStory = [NSMutableDictionary dictionaryWithObject:json forKey:@"where"];
    
    [[AFParseAPIClient sharedClient] getPath:PARSE_API_CLASS_URL(@"Piece")
                                  parameters:getScenesForStory
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSDictionary *response = responseObject;
                                         NSArray *scenes = [response objectForKey:@"results"];
                                         for (NSDictionary *scene in scenes)
                                         {
                                             [Piece deletePiece:[scene objectForKey:@"objectId"]];
                                         }
                                         
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
    
    [Story removeStoryWithId:storyId];
}

+ (void) removeStoryWithId:(NSString *)storyId
{
    [[AFParseAPIClient sharedClient] deletePath:PARSE_API_OBJECT_URL(@"Story", storyId)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            NSLog(@"Story with id %@ deleted", storyId);
                                            NETWORK_OPERATION_COMPLETE();
                                        }
                                        failure:BN_ERROR_BLOCK_OPERATION_INCOMPLETE()];
}
@end
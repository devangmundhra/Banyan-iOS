//
//  Scene+Delete.m
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene+Delete.h"
#import "Story.h"
#import "Story_Defines.h"
#import "Scene_Defines.h"
#import "StoryDocuments.h"

@implementation Piece (Delete)

+ (void) deleteSceneFromDisk:(Piece *)scene
{
    NSLog(@"%s SceneId: %@", __PRETTY_FUNCTION__, scene.pieceId);
    
    Story *story = scene.story;
    
    // Delete scene
    if (scene.image || scene.imageURL)
    {
        NSLog(@"Scene Image still needs to be deleted");
    }
    
    INCREMENT_STORY_ATTRIBUTE_OPERATION(story, STORY_LENGTH, -1);
    
    // ARCHIVE
    NSMutableArray *currentScenes = [story.pieces mutableCopy];
    [currentScenes removeObject:scene];
    story.pieces = [currentScenes copy];
    story.lengthOfStory = [NSNumber numberWithInt:([story.lengthOfStory intValue] - 1)];
    
    if (scene.nextPiece != nil)
    {
        scene.previousPiece.nextPiece = scene.nextPiece;
        scene.nextPiece.previousPiece = scene.previousPiece;
    } else {
        scene.previousPiece.nextPiece = nil;
    }
    
    [StoryDocuments saveStoryToDisk:story];
    scene = nil;
}

+ (void) deletePiece:(NSString *)pieceId
{
    [[AFParseAPIClient sharedClient] deletePath:PARSE_API_OBJECT_URL(@"Piece", pieceId)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            NSLog(@"Scene with id %@ deleted", pieceId);
                                            NETWORK_OPERATION_COMPLETE();
                                        }
                                        failure:BN_ERROR_BLOCK_OPERATION_INCOMPLETE()];
}
@end

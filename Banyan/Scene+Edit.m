//
//  Scene+Edit.m
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story.h"
#import "Scene+Edit.h"
#import "Scene_Defines.h"
#import "StoryDocuments.h"

@implementation Piece (Edit)

+ (void) editScene:(Piece *)scene
{
    NSMutableDictionary *sceneParams = [NSMutableDictionary dictionaryWithCapacity:1];
    BNOperationDependency *imageDependency = nil;
    
    if (scene.imageChanged)
    {
        scene.imageChanged = NO;
        // Maybe delete the image that was stored previously if another image has
        // come in
        
        if (scene.imageURL)
        {
            // Upload the image (ie, create a network request for that)
            BNOperationObject *imgObj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeFile
                                                                               tempId:scene.imageURL
                                                                              storyId:scene.story.storyId];
            BNOperation *imgOperation = [[BNOperation alloc] initWithObject:imgObj action:BNOperationActionCreate dependencies:nil];
            ADD_OPERATION_TO_QUEUE(imgOperation);
            
            // Create a dependency object
            imageDependency = [[BNOperationDependency alloc] initWithBNObject:imgObj
                                                                        field:PIECE_IMAGE_URL];
        } else {
            // Scene image was deleted
            [sceneParams setObject:[NSNull null] forKey:PIECE_IMAGE_URL];
        }
    }
    
    // Update scene
    [sceneParams setObject:scene.text forKey:PIECE_TEXT];
    
    BNOperationObject *obj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeScene tempId:scene.pieceId storyId:scene.story.storyId];
    BNOperation *operation = [[BNOperation alloc] initWithObject:obj action:BNOperationActionEdit dependencies:nil];
    operation.action.context = sceneParams;
    if (imageDependency) {
        [operation addDependencyObject:imageDependency];
    }
    ADD_OPERATION_TO_QUEUE(operation);

    [StoryDocuments saveStoryToDisk:scene.story];
    
    return;
}

+ (void) editScene:(Piece *)scene withAttributes:(NSMutableDictionary *)sceneParams
{
    [[AFParseAPIClient sharedClient] putPath:PARSE_API_OBJECT_URL(@"Piece", scene.pieceId)
                                  parameters:sceneParams
                                     success:^(AFHTTPRequestOperation *operations, id responseObject) {
                                         NSDictionary *response = responseObject;
                                         NSLog(@"Got response for updating scene parameters %@ at %@", sceneParams, [response objectForKey:@"updatedAt"]);
                                         NETWORK_OPERATION_COMPLETE();
                                     }
                                     failure:BN_ERROR_BLOCK_OPERATION_COMPLETE()];
    
    [StoryDocuments saveStoryToDisk:scene.story];
    
    return;
}

- (void)incrementSceneAttribute:(NSString *)attribute byAmount:(NSNumber *)inc
{    
    NSMutableDictionary *sceneEditParams = [NSMutableDictionary dictionaryWithCapacity:1];
    
    NSDictionary *sceneAttrInc = [NSDictionary dictionaryWithObjectsAndKeys:@"Increment", @"__op", 
                                    inc, @"amount", nil];
    [sceneEditParams setObject:sceneAttrInc forKey:attribute];
    
    [[AFParseAPIClient sharedClient] putPath:PARSE_API_OBJECT_URL(@"Piece", self.pieceId)
                                  parameters:sceneEditParams
                                     success:^(AFHTTPRequestOperation *operations, id responseObject) {
                                         NSDictionary *response = responseObject;
                                         NSLog(@"Got response for updating scene %@ at %@", attribute, [response objectForKey:@"updatedAt"]);
                                         NETWORK_OPERATION_COMPLETE();
                                     }
                                     failure:BN_ERROR_BLOCK_OPERATION_COMPLETE()];
}

@end

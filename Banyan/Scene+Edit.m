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

@implementation Scene (Edit)

+ (void) editScene:(Scene *)scene
{
    if (![[ParseAPIEngine sharedEngine] isReachable]) {
        NSLog(@"%s Can't connect to internet", __PRETTY_FUNCTION__);
        [ParseAPIEngine showNetworkUnavailableAlert];
        return;
    }
    
    NSMutableDictionary *sceneParams = [NSMutableDictionary dictionaryWithCapacity:1];
    
    PFFile *imageFile = nil;
    if (scene.image)
    {
        // Maybe delete the image that was stored previously if another image has
        // come in
        NSData *imageData = UIImagePNGRepresentation(scene.image);
        imageFile= [PFFile fileWithName:[scene.sceneId stringByAppendingString:@".png"] data:imageData];
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                scene.imageURL = imageFile.url;
                NSMutableDictionary *imageURLParam = [NSMutableDictionary dictionaryWithObject:imageFile.url 
                                                                                        forKey:SCENE_IMAGE_URL];
                MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", scene.sceneId) 
                                                                                   params:imageURLParam
                                                                               httpMethod:@"PUT" 
                                                                                      ssl:YES];
                [op onCompletion:^(MKNetworkOperation *completedOperation) {
                    NSLog(@"Updating scene with imageURL %@", imageFile.url);
                }  
                         onError:PARSE_ERROR_BLOCK()];
                [[ParseAPIEngine sharedEngine] enqueueOperation:op];
            }
            else
                NSLog(@"%s Error %@: Can't save image for scene", __PRETTY_FUNCTION__, error);
        }];
    }
    
    // Update scene
    [sceneParams setObject:scene.text forKey:SCENE_TEXT];
    
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", scene.sceneId) 
                                                                       params:sceneParams
                                                                   httpMethod:@"PUT" 
                                                                          ssl:YES];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSDictionary *response = [completedOperation responseJSON];
        NSLog(@"Got response for updating scene parameters at %@", [response objectForKey:@"updatedAt"]);
    }  
             onError:PARSE_ERROR_BLOCK()];
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];

    [StoryDocuments saveStoryToDisk:scene.story];
    
    return;
}

- (void)incrementSceneAttribute:(NSString *)attribute byAmount:(NSNumber *)inc
{    
    NSMutableDictionary *sceneEditParams = [NSMutableDictionary dictionaryWithCapacity:1];
    
    NSDictionary *sceneAttrInc = [NSDictionary dictionaryWithObjectsAndKeys:@"Increment", @"__op", 
                                    inc, @"amount", nil];
    [sceneEditParams setObject:sceneAttrInc forKey:attribute];
    
    MKNetworkOperation *op = [[ParseAPIEngine sharedEngine] operationWithPath:PARSE_API_OBJECT_URL(@"Scene", self.sceneId) 
                                                                       params:sceneEditParams
                                                                   httpMethod:@"PUT" 
                                                                          ssl:YES];
    [op
     onCompletion:^(MKNetworkOperation *completedOperation) {
         NSDictionary *response = [completedOperation responseJSON];
         NSLog(@"Got response for updating scene %@ at %@", attribute, [response objectForKey:@"updatedAt"]);
     } 
     onError:PARSE_ERROR_BLOCK()];
    
    [[ParseAPIEngine sharedEngine] enqueueOperation:op];
}

@end

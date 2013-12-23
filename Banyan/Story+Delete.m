//
//  Story+Delete.m
//  Storied
//
//  Created by Devang Mundhra on 3/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Delete.h"
#import "AFBanyanAPIClient.h"
#import "MBProgressHUD.h"
#import "BanyanAppDelegate.h"
#import "Media.h"

@implementation Story (Delete)

+ (void) deleteStory:(Story *)story completion:(void (^)(void)) completion;
{
    if (story.remoteStatus == RemoteObjectStatusPushing) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error in deleting story %@", story.title]
                                                        message:@"Can't delete a story while it is being uploaded"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Delete all media for the story
    for (Media *media in story.media) {
        // If its a local image, don't delete it
        if ([media.remoteURL length]) {
            [media deleteWitSuccess:nil
                            failure:nil]; // ignore errors for now
        }
    }
    
    if (story.remoteStatus != RemoteObjectStatusLocal && NUMBER_EXISTS(story.bnObjectId)) {
        NSNumber *storyId = story.bnObjectId;
        NSLog(@"%s Story id: %@", __PRETTY_FUNCTION__, storyId);
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[APP_DELEGATE topMostController].view animated:YES];
        hud.labelText = @"Deleting story";
        
        [[AFBanyanAPIClient sharedClient] deletePath:[NSString stringWithFormat:@"story/%@/?format=json", storyId]
                                          parameters:nil
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSLog(@"Story with id %@ deleted", storyId);
                                                 [story remove];
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [hud hide:YES];
                                                     if (completion) completion();
                                                 });
                                             }
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [hud hide:YES];
                                                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error in deleting story %@", story.title]
                                                                                                     message:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]
                                                                                                    delegate:nil
                                                                                           cancelButtonTitle:@"OK"
                                                                                           otherButtonTitles:nil];
                                                     [alert show];
                                                 });
                                             }
         ];
        [hud hide:YES];
    } else {
        [story remove];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion();
        });
    }
}

@end
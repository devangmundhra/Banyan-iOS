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

+ (void) deleteStory:(Story *)story
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
        else
            [media remove];
    }
    
    if (story.remoteStatus != RemoteObjectStatusLocal && NUMBER_EXISTS(story.bnObjectId)) {
        NSNumber *storyId = story.bnObjectId;
        NSLog(@"%s Story id: %@", __PRETTY_FUNCTION__, storyId);
        
        // For RunLoop
        __block BOOL doneRun = NO;
        __block BOOL success = NO;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[APP_DELEGATE topMostController].view animated:YES];
        hud.labelText = @"Deleting story";
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
        
        [[AFBanyanAPIClient sharedClient] deletePath:BANYAN_API_OBJECT_URL(@"Story", storyId)
                                          parameters:nil
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSLog(@"Story with id %@ deleted", storyId);
                                                 [story remove];
                                                 doneRun = YES;
                                                 success = YES;
                                             }
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error in deleting story %@", story.title]
                                                                                                 message:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]
                                                                                                delegate:nil
                                                                                       cancelButtonTitle:@"OK"
                                                                                       otherButtonTitles:nil];
                                                 [alert show];
                                                 doneRun = YES;
                                             }
         ];
        do
        {
            // Start the run loop but return after each source is handled.
            SInt32    result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, YES);
            
            // If a source explicitly stopped the run loop, or if there are no
            // sources or timers, go ahead and exit.
            if ((result == kCFRunLoopRunStopped) || (result == kCFRunLoopRunFinished))
                doneRun = YES;
            
            // Check for any other exit conditions here and set the
            // done variable as needed.
        }
        while (!doneRun);
        [hud hide:YES];
    } else {
        [story remove];
    }    
}

@end
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
    if ([[story calculateUploadStatusNumber] unsignedIntegerValue] != RemoteObjectStatusSync) {
        [story cancelAnyOngoingOperation];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction Skipped" action:@"story delete" label:@"pending changes" value:nil];
    }
    
    if (story.remoteStatus != RemoteObjectStatusLocal && NUMBER_EXISTS(story.bnObjectId)) {
        NSNumber *storyId = story.bnObjectId;
        BNLogInfo(@"Deleting story id: %@", storyId);
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[APP_DELEGATE topMostController].view animated:YES];
        hud.labelText = @"Deleting story";
        
        [[AFBanyanAPIClient sharedClient] deletePath:[NSString stringWithFormat:@"story/%@/?format=json", storyId]
                                          parameters:nil
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 BNLogInfo(@"Story with id %@ deleted", storyId);
                                                 [story remove];
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [hud hide:YES];
                                                     if (completion) completion();
                                                 });
                                             }
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [hud hide:YES];
                                                     if (operation.response.statusCode == 404) {
                                                         // The story is no longer available on the server. Delete it
                                                         [story remove];
                                                         if (completion) completion();
                                                         return;
                                                     }
                                                     [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error in deleting story %@", story.title]
                                                                                 message:error.localizedDescription
                                                                                delegate:nil
                                                                       cancelButtonTitle:@"OK"
                                                                       otherButtonTitles:nil] show];
                                                 });
                                             }
         ];
    } else {
        [story remove];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion();
        });
    }
}

@end
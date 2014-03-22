//
//  Scene+Delete.m
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece+Delete.h"
#import "Story+Edit.h"
#import "AFBanyanAPIClient.h"
#import "MBProgressHUD.h"
#import "BanyanAppDelegate.h"
#import "Media.h"

@implementation Piece (Delete)

- (void) removeWithStoryUpdate
{
    Story *story = self.story;
    
    self.story = nil;
    [self remove];
    
    [Story syncStoryAttributeWithItsPieces:story];
}

+ (void) deletePiece:(Piece *)piece completion:(void (^)(void)) completion
{
    if (piece.remoteStatus == RemoteObjectStatusPushing) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in deleting piece"
                                                        message:@"Can't delete a piece while it is being uploaded"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction Skipped" action:@"piece delete" label:@"pending changes" value:nil];
        return;
    }

    if (piece.remoteStatus != RemoteObjectStatusLocal && NUMBER_EXISTS(piece.bnObjectId)) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[APP_DELEGATE topMostController].view animated:YES];
        hud.labelText = @"Deleting piece";
        
        [[AFBanyanAPIClient sharedClient] deletePath:[NSString stringWithFormat:@"piece/%@/?format=json", piece.bnObjectId]
                                          parameters:nil
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 BNLogTrace(@"Piece %@ DELETED", piece.bnObjectId);
                                                 [piece removeWithStoryUpdate];
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
                                                         [piece remove];
                                                         if (completion) completion();
                                                         return;
                                                     }
                                                     [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error in deleting piece %@", piece.shortText]
                                                                                 message:error.localizedDescription
                                                                                delegate:nil
                                                                       cancelButtonTitle:@"OK"
                                                                       otherButtonTitles:nil] show];
                                                 });
                                             }
         ];
    } else {
        [piece removeWithStoryUpdate];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion();
        });
    }
}
@end

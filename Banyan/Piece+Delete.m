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
    
    [Story updateLengthAndPieceNumbers:story];
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
        return;
    }
    
    NSOrderedSet *mediaSet = piece.media;
    // Delete all media for the piece
    for (Media *media in mediaSet) {
        // If its a local image, don't delete it
        if ([media.remoteURL length]) {
            [media deleteWitSuccess:nil
                            failure:nil]; // ignore errors for now
        }
        else
            [media remove];
    }

    if (piece.remoteStatus != RemoteObjectStatusLocal && NUMBER_EXISTS(piece.bnObjectId)) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[APP_DELEGATE topMostController].view animated:YES];
        hud.labelText = @"Deleting piece";
        
        [[AFBanyanAPIClient sharedClient] deletePath:[NSString stringWithFormat:@"piece/%@/?format=json", piece.bnObjectId]
                                          parameters:nil
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSLog(@"Piece %@ DELETED", piece.bnObjectId);
                                                 [piece removeWithStoryUpdate];
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [hud hide:YES];
                                                     if (completion) completion();
                                                 });
                                             }
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [hud hide:YES];
                                                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error in deleting piece %@", piece.shortText]
                                                                                                     message:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]
                                                                                                    delegate:nil
                                                                                           cancelButtonTitle:@"OK"
                                                                                           otherButtonTitles:nil];
                                                     [alert show];
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

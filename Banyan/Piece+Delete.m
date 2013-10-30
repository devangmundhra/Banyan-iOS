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

+ (void) deletePiece:(Piece *)piece
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
    
    // Delete all media for the piece
    for (Media *media in piece.media) {
        // If its a local image, don't delete it
        if ([media.remoteURL length]) {
            [media deleteWitSuccess:nil
                            failure:nil]; // ignore errors for now
        }
        else
            [media remove];
    }
    
    // For RunLoop
    __block BOOL doneRun = NO;
    __block BOOL success = NO;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[APP_DELEGATE topMostController].view animated:YES];
    hud.labelText = @"Deleting piece";
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];

    if (piece.remoteStatus != RemoteObjectStatusLocal && NUMBER_EXISTS(piece.bnObjectId)) {
        [[AFBanyanAPIClient sharedClient] deletePath:BANYAN_API_OBJECT_URL(@"Piece", piece.bnObjectId)
                                          parameters:nil
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSLog(@"Piece deleted with response %@", responseObject);
                                                 [piece removeWithStoryUpdate];
                                                 doneRun = YES;
                                                 success = YES;
                                             }
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error in deleting piece %@", piece.shortText]
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
        [piece removeWithStoryUpdate];
    }
}
@end

//
//  Scene+Delete.m
//  Storied
//
//  Created by Devang Mundhra on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece+Delete.h"
#import "Story.h"
#import "AFBanyanAPIClient.h"
#import "MBProgressHUD.h"
#import "BanyanAppDelegate.h"

@implementation Piece (Delete)

- (void) removeWithStoryUpdate
{
    Story *story = self.story;
    
    self.story = nil;
    [self remove];
    
    // Update the length
    story.length = story.pieces.count;
    // Update the value for the piece numbers
    if (!story.length)
        story.pieces = nil;
    else {
        [story.pieces enumerateObjectsUsingBlock:^(Piece *localPiece, NSUInteger idx, BOOL *stop) {
            localPiece.pieceNumber = idx+1;
        }];
    }
    
    [story save];
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
    
    // For RunLoop
    __block BOOL doneRun = NO;
    __block BOOL success = NO;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[BanyanAppDelegate topMostController].view animated:YES];
    hud.labelText = @"Deleting piece";
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];

    if (piece.remoteStatus != RemoteObjectStatusLocal && piece.bnObjectId.length > 0) {
        [[AFBanyanAPIClient sharedClient] deletePath:BANYAN_API_OBJECT_URL(@"Piece", piece.bnObjectId)
                                          parameters:nil
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSLog(@"Piece deleted with response %@", responseObject);
                                                 [piece removeWithStoryUpdate];
                                                 doneRun = YES;
                                                 success = YES;                                             }
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

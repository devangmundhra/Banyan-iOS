//
//  ReadSceneViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Piece_Defines.h"
#import "Story_Defines.h"
#import "Story+Edit.h"
#import "BanyanAppDelegate.h"
#import "User_Defines.h"
#import "InvitedTableViewController.h"
#import "ASMediaFocusManager.h"
#import "BNAudioStreamingPlayer.h"

@class ReadPieceViewController;

@protocol ReadPieceViewControllerDelegate <NSObject, UIGestureRecognizerDelegate>

- (BOOL) readPieceViewControllerFlipToPiece:(NSNumber *)pieceNumber;
- (void) setCurrentPiece:(Piece *)piece;
- (void) readPieceViewControllerDoneReading;
- (UIPanGestureRecognizer *) dismissPanGestureRecognizer;

@end

@interface ReadPieceViewController : UIViewController <InvitedTableViewControllerDelegate, ASMediasFocusDelegate>

@property (strong, nonatomic) Piece *piece;
@property (weak, nonatomic) IBOutlet UIViewController<ReadPieceViewControllerDelegate> *delegate;

- (id) initWithPiece:(Piece *)piece;
- (void) addGestureRecognizerToContentView:(UIGestureRecognizer *)gR;

@end
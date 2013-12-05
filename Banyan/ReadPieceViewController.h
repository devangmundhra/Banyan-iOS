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
#import "BNAudioStreamingPlayer.h"

@class ReadPieceViewController;

@protocol ReadPieceViewControllerDelegate <NSObject>

- (BOOL) readPieceViewControllerFlipToPiece:(NSNumber *)pieceNumber;
- (void) setCurrentPiece:(Piece *)piece;
- (void) readPieceViewControllerDoneReading;
- (UIPanGestureRecognizer *) dismissBackPanGestureRecognizer;
- (UIPanGestureRecognizer *) dismissAheadPanGestureRecognizer;

@end

@interface ReadPieceViewController : UIViewController

@property (strong, nonatomic) Piece *piece;
@property (weak, nonatomic) IBOutlet id<ReadPieceViewControllerDelegate> delegate;

- (id) initWithPiece:(Piece *)piece;
- (void) addGestureRecognizerToContentView:(UIGestureRecognizer *)gR;

@end
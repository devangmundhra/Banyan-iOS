//
//  ReadSceneViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 3/31/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story+Edit.h"
#import "BanyanAppDelegate.h"
#import "BNAudioStreamingPlayer.h"

@class ReadPieceViewController;

@protocol ReadPieceViewControllerDelegate <NSObject>

- (BOOL) readPieceViewControllerFlipToPieceAtIndex:(NSUInteger)pieceIndexNumber;
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
//
//  StoryReaderController.h
//  Storied
//
//  Created by Devang Mundhra on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReadPieceViewController.h"
#import "Story.h"
#import "Piece.h"
#import "ModifyPieceViewController.h"

@class StoryReaderController;

#define HUD_STAY_DELAY 1.2 // amount of time HUD progress bar stays (in seconds)

@interface StoryReaderController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, ReadPieceViewControllerDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, ModifyPieceViewControllerDelegate>

@property (nonatomic, strong) Story *story;
@property (nonatomic, strong) UIPageViewController *pageViewController;

- (id)initWithPiece:(Piece *)piece;


@end

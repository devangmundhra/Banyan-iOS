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

@class StoryReaderController;

#define HUD_STAY_DELAY 1.2 // amount of time HUD progress bar stays (in seconds)

@interface StoryReaderController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, ReadPieceViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) Story *story;
@property (nonatomic, strong) UIPageViewController *pageViewController;

- (NSUInteger)indexOfViewController:(ReadPieceViewController *)viewController;
- (ReadPieceViewController *)viewControllerAtIndex:(NSUInteger)index;

@end

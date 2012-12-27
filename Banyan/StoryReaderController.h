//
//  StoryReaderController.h
//  Storied
//
//  Created by Devang Mundhra on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReadSceneViewController.h"
#import "Story.h"
#import "Piece.h"

@class StoryReaderController;

#define HUD_STAY_DELAY 1.2 // amount of time HUD progress bar stays (in seconds)

@protocol StoryReaderControllerDelegate <NSObject>

- (void)storyReaderContollerDone:(StoryReaderController *)scenesViewController;

@end

@interface StoryReaderController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate, ReadSceneViewControllerDelegate>

@property (nonatomic, strong) Story *story;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, weak) IBOutlet id <StoryReaderControllerDelegate> delegate;
@property (nonatomic) BOOL readSceneControllerEditMode;

- (NSUInteger)indexOfViewController:(ReadSceneViewController *)viewController;
- (ReadSceneViewController *)viewControllerAtIndex:(NSUInteger)index;

@end

//
//  ScenesViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReadSceneViewController.h"
#import "Story.h"
#import "Scene.h"

@class ScenesViewController;

#define HUD_STAY_DELAY 1.2 // amount of time HUD progress bar stays (in seconds)

@protocol ScenesViewControllerDelegate <NSObject>

- (void)scenesViewContollerDone:(ScenesViewController *)scenesViewController;

@end

@interface ScenesViewController : UIViewController </*UIGestureRecognizerDelegate, */UIPageViewControllerDataSource, UIPageViewControllerDelegate, ReadSceneViewControllerDelegate>

@property (nonatomic, strong) Story *story;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, weak) IBOutlet id <ScenesViewControllerDelegate> delegate;
@property (nonatomic) BOOL readSceneControllerEditMode;

- (NSUInteger)indexOfViewController:(ReadSceneViewController *)viewController;
- (ReadSceneViewController *)viewControllerAtIndex:(NSUInteger)index;

@end

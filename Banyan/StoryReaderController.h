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

@protocol StoryReaderControllerDelegate <NSObject>

- (void) storyReaderControllerReadNextStory:(Story *)nextStory;
- (Story *) storyReaderControllerGetNextStory:(StoryReaderController *)storyReaderController;

@end

@interface StoryReaderController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, strong) Story *story;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet id<StoryReaderControllerDelegate> delegate;

- (id)initWithPiece:(Piece *)piece;


@end
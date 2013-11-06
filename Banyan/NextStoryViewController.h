//
//  NextStoryViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 11/5/13.
//
//

#import <UIKit/UIKit.h>
#import "Story.h"

@class NextStoryViewController;

@protocol NextStoryViewControllerDelegate <NSObject>

- (void) nextStoryViewControllerGoToStoryList:(NextStoryViewController *)nextStoryViewController;
- (void) nextStoryViewControllerGoToStory:(Story *)nextStory;
- (void) nextStoryViewControllerAddPieceToStory:(NextStoryViewController *)nextStoryViewController;

- (UIPanGestureRecognizer *) dismissAheadPanGestureRecognizer;

@end

@interface NextStoryViewController : UIViewController
@property (weak, nonatomic) IBOutlet id<NextStoryViewControllerDelegate> delegate;
@property (strong, nonatomic) Story *nextStory;
@property (strong, nonatomic) Story *currentStory;
@end

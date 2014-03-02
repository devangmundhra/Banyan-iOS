//
//  SingleStoryView.h
//  Banyan
//
//  Created by Devang Mundhra on 6/16/13.
//
//

#import <UIKit/UIKit.h>
#import "Story.h"
#import "BNSwipeableView.h"
#import <QuartzCore/QuartzCore.h>

#define TABLE_CELL_MARGIN 10.0
#define TOP_VIEW_HEIGHT 50
#define MIDDLE_VIEW_HEIGHT 130
#define BOTTOM_VIEW_HEIGHT 30
#define BUTTON_SPACING 20.0
// (sum of these) + (top margin) = (table view height - 220)
#define TABLE_ROW_HEIGHT 220.0

@class SingleStoryView;

@protocol SingleStoryViewDelegate <NSObject>

- (void)addPiece:(id)sender;
- (void)flagStory:(id)sender withMessage:(NSString *)message;
- (void)shareStory:(id)sender;
- (void)hideStory:(id)sender;

@end

@interface SingleStoryView : UIView <BNSwipeableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) Story *story;
@property (weak, nonatomic) id<SingleStoryViewDelegate> delegate;

- (void) hideSwipedViewAnimated:(BOOL)animated;
- (void) revealSwipedViewAnimated:(BOOL)animated;
@end

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

#define TABLE_CELL_MARGIN 10.0
#define TOP_VIEW_HEIGHT 50
#define MIDDLE_VIEW_HEIGHT 130
#define BOTTOM_VIEW_HEIGHT 30
#define BUTTON_SPACING 20.0
// (sum of these) + (top margin) = (table view height - 220)
#define TABLE_ROW_HEIGHT 220.0

@class SingleStoryView;

@protocol SingleStoryViewDelegate <NSObject>

- (void)deleteStory:(id)sender;
- (void)addPiece:(id)sender;
- (void)shareStory:(id)sender;

@end

@interface SingleStoryView : UIView <BNSwipeableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) Story *story;
@property (strong, nonatomic) id<SingleStoryViewDelegate> delegate;

- (void) hideSwipedViewAnimated:(BOOL)animated;
- (void) revealSwipedViewAnimated:(BOOL)animated;
@end

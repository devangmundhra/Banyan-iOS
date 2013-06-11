//
//  StoryListCell.h
//  Banyan
//
//  Created by Devang Mundhra on 3/18/13.
//
//

#import <UIKit/UIKit.h>
#import "Story.h"
#import "Story_Defines.h"
#import "BNSwipeableView.h"

#define TABLE_CELL_MARGIN 10.0
#define TABLE_ROW_HEIGHT 220.0 // from nib file

@class StoryListCell;

@protocol StoryListCellDelegate <NSObject, UITableViewDataSource>

- (void) addPieceForStoryListCell:(StoryListCell *)cell;
- (void) deleteStoryForStoryListCell:(StoryListCell *)cell;
- (void) shareStoryForStoryListCell:(StoryListCell *)cell;

@end

@interface StoryListCell : UITableViewCell <BNSwipeableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) IBOutlet Story* story;
@property (nonatomic, strong) id<StoryListCellDelegate> delegate;

- (void) hideSwipedViewAnimated:(BOOL)animated;
- (void) revealSwipedViewAnimated:(BOOL)animated;
- (Piece *)currentlyVisiblePiece;

@end

@interface UIViewWithTopLine : UIView
@end
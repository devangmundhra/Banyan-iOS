//
//  SingleStoryCell.h
//  Banyan
//
//  Created by Devang Mundhra on 6/16/13.
//
//

#import <UIKit/UIKit.h>
#import "Story.h"
#import "SingleStoryView.h"
#import "BNPiecesScrollView.h"

@class SingleStoryCell;

@protocol SingleStoryCellDelegate <NSObject>

- (void) addPieceForSingleStoryCell:(SingleStoryCell *)cell;
- (void) deleteStoryForSingleStoryCell:(SingleStoryCell *)cell;
- (void) shareStoryForSingleStoryCell:(SingleStoryCell *)cell;
- (void) hideStoryForSingleStoryCell:(SingleStoryCell *)cell;

@end

@interface SingleStoryCell : UITableViewCell <SingleStoryViewDelegate, UIScrollViewDelegate>

@property (nonatomic, weak) UITableViewController<SingleStoryCellDelegate> *delegate;

- (void) setStory:(Story *)story;
- (Piece *) currentlyVisiblePiece;

@end
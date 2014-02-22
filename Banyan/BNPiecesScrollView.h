//
//  BNPiecesScrollView.h
//  Banyan
//
//  Created by Devang Mundhra on 6/16/13.
//
//

#import <UIKit/UIKit.h>
#import "SinglePieceView.h"
#import "Story.h"

#define PIECE_SCROLL_VIEW_MARGIN 10.0 // Currently same as TABLE_CELL_MARGIN

@interface BNPiecesScrollView : UIScrollView

@property (strong, nonatomic) Story *story;
@property (nonatomic) NSUInteger currentPieceIndexNum;

- (void) scrollToPieceIndexNumber:(NSUInteger)pieceIndexNum;
- (void) resetView;

@end

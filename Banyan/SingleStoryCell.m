//
//  SingleStoryCell.m
//  Banyan
//
//  Created by Devang Mundhra on 6/16/13.
//
//

#import "SingleStoryCell.h"

@interface SingleStoryCell ()

@property (strong, nonatomic) SingleStoryView *storyView;
@property (strong, nonatomic) BNPiecesScrollView *piecesScrollView;
@property (strong, nonatomic) UIGestureRecognizer *tapRecognizer;
@property (strong, nonatomic) Story *story;
@end

@implementation SingleStoryCell

@synthesize delegate = _delegate;
@synthesize tapRecognizer = _tapRecognizer;
@synthesize storyView = _storyView;
@synthesize story = _story;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.contentView.opaque = YES;
        self.backgroundColor = BANYAN_LIGHTGRAY_COLOR;
        self.contentView.backgroundColor = BANYAN_LIGHTGRAY_COLOR;
        
        CGRect ssvFrame = CGRectMake(TABLE_CELL_MARGIN, TABLE_CELL_MARGIN, self.contentView.bounds.size.width - 2 * TABLE_CELL_MARGIN,
                                     self.contentView.bounds.size.height - TABLE_CELL_MARGIN);
		self.storyView = [[SingleStoryView alloc] initWithFrame:ssvFrame];
		self.storyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.storyView.delegate = self;
		[self.contentView addSubview:self.storyView];
        
        self.piecesScrollView = [[BNPiecesScrollView alloc] initWithFrame:CGRectMake(PIECE_SCROLL_VIEW_MARGIN, TABLE_CELL_MARGIN+TOP_VIEW_HEIGHT,
                                                                                     CGRectGetWidth(self.contentView.bounds)-2*PIECE_SCROLL_VIEW_MARGIN,
                                                                                     MIDDLE_VIEW_HEIGHT)];
        [self.piecesScrollView addGestureRecognizer:self.tapRecognizer];
        self.piecesScrollView.delegate = self;
        [self insertSubview:self.piecesScrollView aboveSubview:self.storyView];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

    }
    return self;
}

- (UIGestureRecognizer *)tapRecognizer
{
    if (!_tapRecognizer)
        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(readStory:)];
    return _tapRecognizer;
}

- (void)readStory:(id)sender
{
    NSIndexPath * myIndexPath = [self.delegate.tableView indexPathForCell:self];
    
    if ([self.delegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)]) {
        if ([self.delegate tableView:self.delegate.tableView willSelectRowAtIndexPath:myIndexPath]) {
            [self.delegate.tableView selectRowAtIndexPath:myIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            if ([self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                [self.delegate tableView:self.delegate.tableView didSelectRowAtIndexPath:myIndexPath];
            }
        }
    }
}

- (void)setStory:(Story *)story
{
    _story = story;
    [self.storyView setStory:story];
    [self.piecesScrollView setStory:story];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self hideSwipedViewAnimated:YES];
    [self.piecesScrollView resetView];
}
#pragma mark UIScrollView delegate for PiecesScrollView
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = CGRectGetWidth(self.piecesScrollView.frame);
    NSUInteger page = floor((self.piecesScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    [self.piecesScrollView scrollToPieceNumber:page+1];
}

#pragma SingleStoryView delegate
- (void)deleteStory:(id)sender
{
    [self.delegate deleteStoryForSingleStoryCell:self];
}

- (void)addPiece:(id)sender
{
    [self.delegate addPieceForSingleStoryCell:self];
}

- (void)shareStory:(id)sender
{
    [self.delegate shareStoryForSingleStoryCell:self];
}

- (void)hideStory:(id)sender
{
    [self.delegate hideStoryForSingleStoryCell:self];
}

- (void) redisplay
{
    [self.storyView setNeedsDisplay];
    [self.piecesScrollView setNeedsDisplay];
}

- (void) hideSwipedViewAnimated:(BOOL)animated
{
    [self.storyView hideSwipedViewAnimated:animated];
}

- (void) revealSwipedViewAnimated:(BOOL)animated
{
    [self.storyView revealSwipedViewAnimated:animated];
}

- (Piece *) currentlyVisiblePiece
{
    if (!self.story || ![self.story.pieces count])
        return nil;
    NSUInteger pieceNum = self.piecesScrollView.currentPieceNum;
    Piece *piece = [Piece pieceForStory:self.story withAttribute:@"pieceNumber" asValue:[NSNumber numberWithUnsignedInteger:pieceNum]];
    return piece;
}

@end

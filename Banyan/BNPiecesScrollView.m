//
//  BNPiecesScrollView.m
//  Banyan
//
//  Created by Devang Mundhra on 6/16/13.
//
//

#import "BNPiecesScrollView.h"
#import "BanyanConnection.h"
#import "BanyanAppDelegate.h"

#define NUM_PIECES_WINDOW 5
#define NUM_SINGLE_VIEW_OBJS 7

static UIFont *_boldFont;
static UIFont *_regularFont;

@interface BNPiecesScrollView ()

@property (strong, nonatomic) NSMutableSet *pieceSubviewsInuseList;
@property (strong, nonatomic) NSMutableSet *pieceSubviewsFreeList;
@property (weak, nonatomic) NSOrderedSet *allPieces;
@property (strong, nonatomic) UILabel *statusLabel;

@end

@implementation BNPiecesScrollView

@synthesize pieceSubviewsInuseList = _pieceSubviewsInuseList;
@synthesize pieceSubviewsFreeList = _pieceSubviewsFreeList;
@synthesize story = _story;
@synthesize currentPieceIndexNum = _currentPieceIndexNum;
@synthesize allPieces = _allPieces;
@synthesize statusLabel = _statusLabel;

+ (void)initialize
{
    _boldFont = [UIFont fontWithName:@"Roboto-Bold" size:20];
    _regularFont = [UIFont fontWithName:@"Roboto-Regular" size:12];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = YES;
        self.backgroundColor = BANYAN_WHITE_COLOR;
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.scrollsToTop = NO;
        self.clipsToBounds = NO;
        
        self.pieceSubviewsInuseList = [NSMutableSet set];
        self.pieceSubviewsFreeList = [NSMutableSet setWithCapacity:NUM_SINGLE_VIEW_OBJS];
        
        for (int i = 0; i < NUM_SINGLE_VIEW_OBJS; i++) {
            SinglePieceView *view = [[SinglePieceView alloc] initWithFrame:frame];
            view.hidden = YES;
            assert(![view superview]);
            [self.pieceSubviewsFreeList addObject:view];
            [self addSubview:view];
        }
        
        self.contentSize = CGSizeZero;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMemoryWarnings:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
    }
    return self;
}

- (void) allocateStatusLabel
{
    CGRect localFrame = self.bounds;
    localFrame.origin.x += 15;
    localFrame.origin.y += 10;
    localFrame.size.width -= 30;
    localFrame.size.height -= 20;
    self.statusLabel = [[UILabel alloc] initWithFrame:localFrame];
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.backgroundColor = BANYAN_WHITE_COLOR;
    self.statusLabel.font = _boldFont;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:self.statusLabel];
}

- (void) deallocateStatusLabel
{
    [self.statusLabel removeFromSuperview];
    self.statusLabel = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setStory:(Story *)story
{
    NSUInteger currentPcNumIndex = story.currentPieceIndexNum;
    if (_story && story && _story == story) {
        // If the story hasn't changed, don't change the index
        currentPcNumIndex = self.currentPieceIndexNum;
    }
    _story = story;
    self.allPieces = _story.pieces;
    self.contentSize = CGSizeMake(story.length*self.frame.size.width, self.frame.size.height);
    
    [self scrollRectToVisible:[self calculateFrameForPieceIndexNum:currentPcNumIndex] animated:NO];
    [self scrollToPieceIndexNumber:currentPcNumIndex];
    [self addMsgOnPieceViewIfNeeded];
}

- (SinglePieceView *) addPieceSubviewAtFrame:(CGRect)frame forPieceIndexNum:(NSUInteger)pieceIndexNum
{
    __block SinglePieceView *view = nil;
    
    // If a view already exists for that piece, use that view
    [self.pieceSubviewsInuseList enumerateObjectsUsingBlock:^(SinglePieceView *obj, BOOL *stop) {
        if (obj.pieceIndexNum == pieceIndexNum) {
            view = obj;
            *stop = YES;
        }
    }];
    
    if (view)
        return view;
    
    // Else look for an empty view
    if (!self.pieceSubviewsFreeList.count) {
        view = [[SinglePieceView alloc] initWithFrame:frame];
    } else {
        view = [self.pieceSubviewsFreeList anyObject];
        [self.pieceSubviewsFreeList removeObject:view];
        view.frame = frame;
    }

    view.pieceIndexNum = pieceIndexNum;
    [self.pieceSubviewsInuseList addObject:view];
    // A view in use should not be hidden
    view.hidden = NO;
    return view;
}

- (void) removePieceSubview:(SinglePieceView *)view
{
    // Hide the view since it won't be used
    view.hidden = YES;
    [view resetView];
    [self.pieceSubviewsInuseList removeObject:view];
    
    if (self.pieceSubviewsInuseList.count + self.pieceSubviewsFreeList.count < NUM_SINGLE_VIEW_OBJS)
        [self.pieceSubviewsFreeList addObject:view];
    else {
        // We don't need this view anymore since this was one of the extra ones
        [view removeFromSuperview];
        view = nil;
    }
}

- (CGRect) calculateFrameForPieceIndexNum:(NSUInteger)pieceIndexNum
{
    if (pieceIndexNum == NSNotFound || pieceIndexNum >= self.story.length) {
#ifdef DEBUG
        return CGRectZero;
#else
        pieceIndexNum = 0;
#endif
    }

    CGRect frame = self.frame;
    frame.origin.x = pieceIndexNum*self.frame.size.width;
    frame.origin.y = 0;
    frame.size = self.frame.size;
    return frame;
}

- (void) scrollToPieceIndexNumber:(NSUInteger)pieceIndexNum
{
    if (pieceIndexNum == NSNotFound || pieceIndexNum >= self.story.length) {
#ifdef DEBUG
        return;
#else
        pieceIndexNum = 0;
#endif
    }
    
    self.currentPieceIndexNum = pieceIndexNum;
    
    // Release rest of the subviews which are outside the window
    NSSet *tempSet = [self.pieceSubviewsInuseList objectsPassingTest:^BOOL(SinglePieceView *obj, BOOL *stop) {
        return (!(obj.pieceIndexNum >= pieceIndexNum - floor(NUM_PIECES_WINDOW/2) && obj.pieceIndexNum <= pieceIndexNum + floor(NUM_PIECES_WINDOW/2)));
    }];
    
    __weak BNPiecesScrollView *wself = self;
    [tempSet enumerateObjectsUsingBlock:^(SinglePieceView *obj, BOOL *stop){
        [wself removePieceSubview:obj];
    }];
    
    // Load up all the pieces for and around the current piece number
    int minPieceIndexNum = MAX(pieceIndexNum - floor(NUM_PIECES_WINDOW/2), 0);
    int maxPieceIndexNum = MIN(pieceIndexNum + floor(NUM_PIECES_WINDOW/2), self.story.length-1);
    for (int i = minPieceIndexNum; i <= maxPieceIndexNum; i++) {
        CGRect frame = [self calculateFrameForPieceIndexNum:i];
        if (!CGRectEqualToRect(CGRectZero, frame)) {
            SinglePieceView *pv = [self addPieceSubviewAtFrame:frame forPieceIndexNum:i];
            [self loadPieceWithIndexNum:i atView:pv];
        }
    }
}

- (void) loadPieceWithIndexNum:(NSUInteger)pieceIndexNum atView:(SinglePieceView *)view
{
    if ([self.allPieces indexOfObject:view.piece] == pieceIndexNum && [view.piece.story isEqual:self.story]) {
        return;
    }
    
    @try {
        Piece *piece = nil;
        
        // First try to get it from the local cache
        if (pieceIndexNum < self.allPieces.count) {
            piece = [self.allPieces objectAtIndex:pieceIndexNum];
        }
        if (piece) {
            [view setPiece:piece];
        } else {
            [view setStatusForView:@"There was a problem in fetching this piece" font:_regularFont];
        }
    }
    @catch (NSException *exception) {
        [view setStatusForView:@"There was a problem in fetching this piece" font:_regularFont];
        [BNMisc sendGoogleAnalyticsException:exception inAction:@"Fetching piece in scroll view" isFatal:NO];
        BNLogError(@"Error in setting piece: Exception name: %@, reason: %@, userinfo: %@", exception.name, exception.reason, exception.userInfo);
    }
}

- (void)resetView
{
    [self deallocateStatusLabel];
    // Release all the subviews which are outside the window
    NSArray *tempSet = [self.pieceSubviewsInuseList allObjects];
    __weak BNPiecesScrollView *wself = self;
    [tempSet enumerateObjectsUsingBlock:^(SinglePieceView *obj, NSUInteger idx, BOOL *stop) {
        [wself removePieceSubview:obj];
    }];
}

- (void) addMsgOnPieceViewIfNeeded
{
    if (self.story && !self.story.length) {
        
        [self allocateStatusLabel];
        
        if ([BanyanAppDelegate loggedIn]) {
            if (self.story.canContribute) {
                self.statusLabel.text = @"No pieces in the story.\nClick to add a piece!";
                self.statusLabel.textColor = BANYAN_GREEN_COLOR;
            }
            else {
                self.statusLabel.text = @"No pieces in the story yet!";
                self.statusLabel.textColor = BANYAN_BROWN_COLOR;
            }
        } else {
            self.statusLabel.text = @"No pieces in the story yet.\nLog in to contribute.";
            self.statusLabel.textColor = BANYAN_BROWN_COLOR;
        }
    } else {
        [self deallocateStatusLabel];
    }
}

# pragma mark
# pragma mark Memory management
- (void) handleMemoryWarnings:(id)sender
{
//    [self.pieceSubviewsFreeList removeAllObjects];
}

@end

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
@interface BNPiecesScrollView ()

@property (strong, nonatomic) NSMutableSet *pieceSubviewsInuseList;
@property (strong, nonatomic) NSMutableSet *pieceSubviewsFreeList;
@end

@implementation BNPiecesScrollView

@synthesize pieceSubviewsInuseList = _pieceSubviewsInuseList;
@synthesize pieceSubviewsFreeList = _pieceSubviewsFreeList;
@synthesize story = _story;

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
            SinglePieceView *view = [[SinglePieceView alloc] initWithFrame:CGRectZero];
            assert(![view superview]);
            [self.pieceSubviewsFreeList addObject:view];
        }
        
        self.contentSize = CGSizeZero;
    }
    return self;
}

- (void)setStory:(Story *)story
{
    _story = story;
    if (story && ![story.length integerValue]) {
        [self setNeedsDisplay];
    }
    self.contentSize = CGSizeMake([story.length intValue]*self.frame.size.width, self.frame.size.height);
    [self scrollRectToVisible:[self calculateFrameForPieceNum:story.currentPieceNum] animated:NO];
    [self scrollToPieceNumber:story.currentPieceNum];
}

- (SinglePieceView *) addPieceSubviewAtFrame:(CGRect)frame forPieceNum:(NSUInteger)pieceNum
{
    __block SinglePieceView *view = nil;
    
    // If a view already exists for that piece, use that view
    [self.pieceSubviewsInuseList enumerateObjectsUsingBlock:^(SinglePieceView *obj, BOOL *stop) {
        if (obj.pieceNum == pieceNum) {
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
    assert(![view superview]);
    view.pieceNum = pieceNum;
    [self.pieceSubviewsInuseList addObject:view];
    [self addSubview:view];
    return view;
}

- (void) removePieceSubview:(SinglePieceView *)view
{
    [view removeFromSuperview];
    [view resetView];
    [self.pieceSubviewsInuseList removeObject:view];
    
    if (self.pieceSubviewsInuseList.count + self.pieceSubviewsFreeList.count < NUM_SINGLE_VIEW_OBJS)
        [self.pieceSubviewsFreeList addObject:view];
    else
        view = nil;
}

- (CGRect) calculateFrameForPieceNum:(NSUInteger)pieceNum
{
    if (!pieceNum || pieceNum > [self.story.length unsignedIntegerValue])
        return CGRectZero;
    
    CGRect frame = self.frame;
    frame.origin.x = (pieceNum - 1)*self.frame.size.width;
    frame.origin.y = 0;
    frame.size = self.frame.size;
    return frame;
}

- (void) scrollToPieceNumber:(NSUInteger)pieceNum
{
    if (!pieceNum || pieceNum > [self.story.length unsignedIntegerValue])
        return;
    
    // Release rest of the subviews which are outside the window
    __block NSMutableSet *tempSet = [NSMutableSet set];
    [self.pieceSubviewsInuseList enumerateObjectsUsingBlock:^(SinglePieceView *obj, BOOL *stop) {
        if (!(obj.pieceNum >= pieceNum - floor(NUM_PIECES_WINDOW/2) && obj.pieceNum <= pieceNum + floor(NUM_PIECES_WINDOW/2)))
            [tempSet addObject:obj];
    }];
    [tempSet enumerateObjectsUsingBlock:^(SinglePieceView *obj, BOOL *stop){
        [self removePieceSubview:obj];
    }];
    
    CGRect currentFrame = [self calculateFrameForPieceNum:pieceNum];
    if (!CGRectEqualToRect(CGRectZero, currentFrame)) {
        SinglePieceView *curPV = [self addPieceSubviewAtFrame:currentFrame forPieceNum:pieceNum];
        [self loadPieceWithNumber:pieceNum atView:curPV];
    }
    NSUInteger prevPrevPieceNum = pieceNum - 2;
    CGRect previousPrevFrame = [self calculateFrameForPieceNum:prevPrevPieceNum];
    if (!CGRectEqualToRect(CGRectZero, previousPrevFrame)) {
        SinglePieceView *prePV = [self addPieceSubviewAtFrame:previousPrevFrame forPieceNum:prevPrevPieceNum];
        [self loadPieceWithNumber:prevPrevPieceNum atView:prePV];
    }
    
    NSUInteger prevPieceNum = pieceNum - 1;
    CGRect previousFrame = [self calculateFrameForPieceNum:prevPieceNum];
    if (!CGRectEqualToRect(CGRectZero, previousFrame)) {
        SinglePieceView *prePV = [self addPieceSubviewAtFrame:previousFrame forPieceNum:prevPieceNum];
        [self loadPieceWithNumber:prevPieceNum atView:prePV];
    }
    
    NSUInteger nextPieceNum = pieceNum + 1;
    CGRect nextFrame = [self calculateFrameForPieceNum:nextPieceNum];
    if (!CGRectEqualToRect(CGRectZero, nextFrame)) {
        SinglePieceView *nextPV = [self addPieceSubviewAtFrame:nextFrame forPieceNum:nextPieceNum];
        [self loadPieceWithNumber:nextPieceNum atView:nextPV];
    }
    NSUInteger nextNextPieceNum = pieceNum + 2;
    CGRect nextNextFrame = [self calculateFrameForPieceNum:nextNextPieceNum];
    if (!CGRectEqualToRect(CGRectZero, nextNextFrame)) {
        SinglePieceView *nextPV = [self addPieceSubviewAtFrame:nextNextFrame forPieceNum:nextNextPieceNum];
        [self loadPieceWithNumber:nextNextPieceNum atView:nextPV];
    }
}

- (void) loadPieceWithNumber:(NSUInteger)pieceNum atView:(SinglePieceView *)view
{
    if ([view.piece.pieceNumber integerValue] == pieceNum && [view.piece.story isEqual:self.story]) {
        [view setNeedsDisplay];
        return;
    }
    
    Piece *piece = [Piece pieceForStory:self.story withAttribute:@"pieceNumber" asValue:[NSNumber numberWithUnsignedInteger:pieceNum]];
    if (piece) {
        [view setPiece:piece];
    } else {
        [view setStatusForView:@"Fetching this piece..."];

        // Store the id of the story that this BanyanConnection method set out to fetch.
        // If the storyIds and pieceNum are still the same when the method returns, that means we can update the SinglePieceView.
        // Otherwise, things have changed so don't bother updatating the piece.
        __block NSString *storyIdBeingLookedUp = [self.story.bnObjectId copy];
        [BanyanConnection loadPiecesForStory:self.story atPieceNumbers:@[[NSNumber numberWithUnsignedInteger:pieceNum]]
                             completionBlock:^{
                                 if (pieceNum == view.pieceNum && [storyIdBeingLookedUp isEqualToString:self.story.bnObjectId]) {
                                     Piece *updatedPiece = [Piece pieceForStory:self.story withAttribute:@"pieceNumber" asValue:[NSNumber numberWithUnsignedInteger:pieceNum]];
                                     if (updatedPiece)
                                         [view setPiece:updatedPiece];
                                 } else {
                                     NSLog(@"Piece changed so skipping it");
                                 }
                             }
                                  errorBlock:^(NSError *error) {
                                      if (pieceNum == view.pieceNum && [storyIdBeingLookedUp isEqualToString:self.story.bnObjectId]) {
                                          NSLog(@"Error in BNPiecesScrollView:loadPieceWithNumber Could not load piece");
                                          [view setStatusForView:[NSString stringWithFormat:@"Error: %@ in fetching this piece", error.localizedDescription]];
                                      } else {
                                          NSLog(@"Piece changed so skipping it");
                                      }
                                  }
         ];
    }
}

- (void)resetView
{
    // Release all the subviews which are outside the window
    __block NSMutableSet *tempSet = [NSMutableSet set];
    [self.pieceSubviewsInuseList enumerateObjectsUsingBlock:^(SinglePieceView *obj, BOOL *stop) {
        [tempSet addObject:obj];
    }];
    [tempSet enumerateObjectsUsingBlock:^(SinglePieceView *obj, BOOL *stop){
        [self removePieceSubview:obj];
    }];
}

- (void)drawRect:(CGRect)rect
{
    if (self.story && ![self.story.length integerValue]) {
        [BANYAN_GREEN_COLOR set];
        CGRect smallRect = CGRectMake(rect.origin.x, round(rect.origin.y+rect.size.height/3), rect.size.width, round(rect.size.height*2/3));
        
        if ([BanyanAppDelegate loggedIn]) {
            if ([self.story.canContribute boolValue]) {
                NSString *addPcMsg = @"No pieces in the story.\nClick to add a piece!";
                [addPcMsg drawInRect:smallRect withFont:[UIFont fontWithName:@"Roboto-Bold" size:20] lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];
            } else {
                [BANYAN_BROWN_COLOR set];
                NSString *addPcMsg = @"No pieces in the story yet!";
                [addPcMsg drawInRect:smallRect withFont:[UIFont fontWithName:@"Roboto-Bold" size:20] lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];
            }
        } else {
            NSString *loginMsg = @"No pieces in the story yet.\nLog in to contribute.";
            [loginMsg drawInRect:smallRect withFont:[UIFont fontWithName:@"Roboto-Bold" size:20] lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];
        }
    }
}

@end

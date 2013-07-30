//
//  SingleStoryView.m
//  Banyan
//
//  Created by Devang Mundhra on 6/16/13.
//
//

#import "SingleStoryView.h"
#import "BanyanAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@interface SingleStoryView ()

@property (strong, nonatomic) BNSwipeableView *topSwipeView;
@property (strong, nonatomic) UIButton *storyFrontViewControl;

@end

static UIImage *_clockSymbolImage;
static UIImage *_locationSymbolImage;
static UIImage *_backViewShowImage;
static UIImage *_backViewHideImage;
static UIImage *_shareBlackImage;
static UIImage *_shareWhiteImage;
static UIImage *_addPieceImage;
static UIImage *_deleteStoryImage;
static NSDateFormatter *_dateFormatter;
static UIFont *_boldFont;
static UIFont *_mediumFont;
static BOOL _loggedIn;

@implementation SingleStoryView
@synthesize story = _story;
@synthesize storyFrontViewControl = _storyFrontViewControl;

+ (void)initialize
{
    // Unlikely to have any subclasses, but check class nevertheless.
    if (self == [SingleStoryView class]) {
        
        _clockSymbolImage = [UIImage imageNamed:@"clockSymbol"];
        _locationSymbolImage = [UIImage imageNamed:@"locationSymbolSmall"];
        _backViewShowImage = [UIImage imageNamed:@"backViewShowButton"];
        _backViewHideImage = [UIImage imageNamed:@"backViewHideButton"];
        _shareBlackImage = [UIImage imageNamed:@"shareButtonBlack"];
        _addPieceImage = [UIImage imageNamed:@"addPieceButton"];
        _deleteStoryImage = [UIImage imageNamed:@"deleteStoryButton"];
        _shareWhiteImage = [UIImage imageNamed:@"shareButtonWhite"];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setDoesRelativeDateFormatting:YES];
        
        _boldFont = [UIFont fontWithName:@"Roboto-Bold" size:20];
        _mediumFont = [UIFont fontWithName:@"Roboto-Medium" size:12];
        
        _loggedIn = [BanyanAppDelegate loggedIn];
        
        // Notifications to handle permission controls
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userLoggedIn:)
                                                     name:BNUserLogInNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userLoggedOut:)
                                                     name:BNUserLogOutNotification
                                                   object:nil];
    }
}

+ (void) userLoggedIn:(NSNotification *)notification
{
    _loggedIn = YES;
}

+ (void) userLoggedOut:(NSNotification *)notification
{
    _loggedIn = NO;
}

+ (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = YES;
        self.backgroundColor = BANYAN_WHITE_COLOR;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.layer setCornerRadius:10.0f];
        [self.layer setMasksToBounds:YES];
        
        self.topSwipeView = [[BNSwipeableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), TOP_VIEW_HEIGHT)];
        self.topSwipeView.delegate = self;
        self.topSwipeView.opaque = YES;
        self.topSwipeView.backgroundColor = self.topSwipeView.frontView.backgroundColor = BANYAN_WHITE_COLOR;
        self.topSwipeView.backView.backgroundColor = BANYAN_DARKGRAY_COLOR;
        
        self.storyFrontViewControl = [UIButton buttonWithType:UIButtonTypeCustom];
        self.storyFrontViewControl.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [self.topSwipeView.frontView addSubview:self.storyFrontViewControl];
        [self addSubview:self.topSwipeView];

    }
    return self;
}

- (void)setStory:(Story *)story
{
    _story = story;
    [self setNeedsDisplay];
    [self.topSwipeView setNeedsDisplay];
    [self setupFrontView];
}

- (void)drawRect:(CGRect)rect
{
    CGPoint point;
    
    // Add the lines to seperate the different views
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, BANYAN_LIGHTGRAY_COLOR.CGColor);
    
    // Draw them with a 2.0 stroke width so they are a bit more visible.
    CGContextSetLineWidth(context, 2.0);
    
    CGContextMoveToPoint(context, 0, TOP_VIEW_HEIGHT); //start at this point
    CGContextAddLineToPoint(context, CGRectGetMaxX(self.frame), TOP_VIEW_HEIGHT); //draw to this point
    
    CGContextMoveToPoint(context, 0, TOP_VIEW_HEIGHT + MIDDLE_VIEW_HEIGHT); //start at this point
    CGContextAddLineToPoint(context, CGRectGetMaxX(self.frame), TOP_VIEW_HEIGHT + MIDDLE_VIEW_HEIGHT); //draw to this point
    
    // and now draw the Path!
    CGContextStrokePath(context);

    NSArray *tags = [self.story.tags componentsSeparatedByString:@","];
    NSString *tagsString = [tags componentsJoinedByString:@" "];
    [[UIColor grayColor] set];
    point.x = TABLE_CELL_MARGIN;
    point.y = TOP_VIEW_HEIGHT + MIDDLE_VIEW_HEIGHT + TABLE_CELL_MARGIN/2;
    [tagsString drawAtPoint:point forWidth:CGRectGetWidth(self.frame) - 2*TABLE_CELL_MARGIN
                   withFont:_mediumFont fontSize:12
              lineBreakMode:NSLineBreakByTruncatingTail baselineAdjustment:UIBaselineAdjustmentAlignCenters];
    
    if ([self.story.uploadStatusNumber unsignedIntegerValue] != RemoteObjectStatusSync) {
        NSString *statusString = self.story.sectionIdentifier;
        point.x = CGRectGetMaxX(self.frame) - TABLE_CELL_MARGIN;
        point.y = TOP_VIEW_HEIGHT + MIDDLE_VIEW_HEIGHT + TABLE_CELL_MARGIN/2;
        CGSize size = CGSizeMake(CGRectGetWidth(self.frame)/2 - TABLE_CELL_MARGIN, BOTTOM_VIEW_HEIGHT);
        CGSize expectedSize = [statusString sizeWithFont:_mediumFont constrainedToSize:size];
        point.x -= expectedSize.width;
        [BANYAN_LIGHTGRAY_COLOR set];
        [statusString drawAtPoint:point forWidth:floor(expectedSize.width) withFont:_mediumFont fontSize:10 lineBreakMode:NSLineBreakByClipping baselineAdjustment:UIBaselineAdjustmentNone];
    }    
}

# pragma mark BNSwipeableView delegates
- (void)drawFrontView:(CGRect)rect
{
#define SPACER_DISTANCE 3.0f

    // Add the lines to seperate the different views
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, BANYAN_LIGHTGRAY_COLOR.CGColor);
    
    // Draw them with a 2.0 stroke width so they are a bit more visible.
    CGContextSetLineWidth(context, 2.0);
    
    CGContextMoveToPoint(context, 0, CGRectGetMaxY(rect)); //start at this point
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect)); //draw to this point
    
    // and now draw the Path!
    CGContextStrokePath(context);
    
    CGPoint point;
    CGSize size, expectedSize, clockStringSize;
    NSString *string;

    // Story title
    [BANYAN_BLACK_COLOR set];
    point = CGPointMake(TABLE_CELL_MARGIN, TABLE_CELL_MARGIN/2);
    [self.story.title drawAtPoint:point
                         forWidth:CGRectGetWidth(self.frame) - TABLE_CELL_MARGIN - BUTTON_SPACING
                         withFont:_boldFont fontSize:20
                    lineBreakMode:NSLineBreakByTruncatingTail baselineAdjustment:UIBaselineAdjustmentNone];
    
    // Time label
    point = CGPointMake(TABLE_CELL_MARGIN+_clockSymbolImage.size.width+SPACER_DISTANCE, TOP_VIEW_HEIGHT/2+SPACER_DISTANCE);
    [[UIColor grayColor] set];
    string = [_dateFormatter stringFromDate:[self.story.createdAt dateByAddingTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT]]];
    size = CGSizeMake(CGRectGetWidth(self.frame)/2 - TABLE_CELL_MARGIN - BUTTON_SPACING, TOP_VIEW_HEIGHT/2);
    expectedSize = [string sizeWithFont:_mediumFont constrainedToSize:size];
    clockStringSize = [string drawAtPoint:point forWidth:floor(expectedSize.width) withFont:_mediumFont fontSize:12 lineBreakMode:NSLineBreakByClipping baselineAdjustment:UIBaselineAdjustmentNone];
    // Time image
    // Center image according to label
    point = CGPointMake(TABLE_CELL_MARGIN, floor(TOP_VIEW_HEIGHT/2 + (clockStringSize.height - _clockSymbolImage.size.height)/2)+SPACER_DISTANCE);
    [_clockSymbolImage drawAtPoint:point];
    
    if (self.story.isLocationEnabled && [self.story.location.name length]) {
        // Location label
        point.x = TABLE_CELL_MARGIN+_clockSymbolImage.size.width+SPACER_DISTANCE+clockStringSize.width+2*SPACER_DISTANCE+_locationSymbolImage.size.width+SPACER_DISTANCE;
        point.y = TOP_VIEW_HEIGHT/2+SPACER_DISTANCE;
        [[UIColor grayColor] set];
        string = self.story.location.name;
        size = CGSizeMake(CGRectGetWidth(self.frame)/2 - TABLE_CELL_MARGIN - BUTTON_SPACING, TOP_VIEW_HEIGHT/2);
        expectedSize = [string sizeWithFont:_mediumFont constrainedToSize:size];
        size = [string drawAtPoint:point forWidth:floor(expectedSize.width) withFont:_mediumFont fontSize:12 lineBreakMode:NSLineBreakByClipping baselineAdjustment:UIBaselineAdjustmentNone];
        // Location image
        // Center image according to label
        point = CGPointMake(TABLE_CELL_MARGIN+_clockSymbolImage.size.width+SPACER_DISTANCE+clockStringSize.width+2*SPACER_DISTANCE,
                            floor(TOP_VIEW_HEIGHT/2 + (size.height - _locationSymbolImage.size.height)/2)+SPACER_DISTANCE);
        [_locationSymbolImage drawAtPoint:point];
    }
}

- (void) setupFrontView
{
    UIImage *frontViewControlImage = nil;
    if (self.story.canContribute && _loggedIn) {
        // Have the reveal Backview button on front view
        frontViewControlImage = _backViewShowImage;
        [self.storyFrontViewControl removeTarget:self.delegate action:@selector(shareStory:) forControlEvents:UIControlEventTouchUpInside];
        [self.storyFrontViewControl addTarget:self action:@selector(showBackView:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        // Just have the share button in front view.
        frontViewControlImage = _shareBlackImage;
        [self.storyFrontViewControl removeTarget:self action:@selector(showBackView:) forControlEvents:UIControlEventTouchUpInside];
        [self.storyFrontViewControl addTarget:self.delegate action:@selector(shareStory:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.storyFrontViewControl setImage:frontViewControlImage forState:UIControlStateNormal];
    // Set the button's frame
    CGRect frontViewControlButtonFrame;
    frontViewControlButtonFrame.origin.x = floor(CGRectGetWidth(self.topSwipeView.frame) - frontViewControlImage.size.width - TABLE_CELL_MARGIN);
    frontViewControlButtonFrame.origin.y = floor(self.topSwipeView.frontView.frame.origin.y);
    frontViewControlButtonFrame.size.height = floor(self.topSwipeView.frontView.bounds.size.height);
    frontViewControlButtonFrame.size.width = floor(frontViewControlImage.size.width);
    self.storyFrontViewControl.frame = frontViewControlButtonFrame;
}

- (void) setupBackView
{
    if (self.story.canContribute)
    {
        // Add backview control button
        UIButton *backViewControlButton = [UIButton buttonWithType:UIButtonTypeCustom];
        // Make sure the button ends up in the right place when the cell is resized
        backViewControlButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [backViewControlButton setImage:_backViewHideImage forState:UIControlStateNormal];
        [backViewControlButton addTarget:self action:@selector(hideBackView:) forControlEvents:UIControlEventTouchUpInside];
        // Set the button's frame
        CGRect backViewControlButtonFrame = backViewControlButton.bounds;
        backViewControlButtonFrame.origin.x = TABLE_CELL_MARGIN;
        backViewControlButtonFrame.origin.y = self.topSwipeView.backView.bounds.origin.y;
        backViewControlButtonFrame.size = _backViewHideImage.size;
        backViewControlButtonFrame.size.height = self.topSwipeView.backView.bounds.size.height;
        backViewControlButton.frame = backViewControlButtonFrame;
        
        [self.topSwipeView.backView addSubview:backViewControlButton];
        
        // Add Piece Button
        UIButton *addPieceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        // Make sure the button ends up in the right place when the cell is resized
        addPieceButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [addPieceButton setImage:_addPieceImage forState:UIControlStateNormal];
        [addPieceButton addTarget:self.delegate action:@selector(addPiece:) forControlEvents:UIControlEventTouchUpInside];
        // Set the button's frame
        CGRect addPieceButtonFrame = addPieceButton.bounds;
        addPieceButtonFrame.origin.x = floor(CGRectGetMaxX(backViewControlButton.frame) + BUTTON_SPACING);
        addPieceButtonFrame.origin.y = floor(self.topSwipeView.backView.bounds.origin.y);
        addPieceButtonFrame.size = _addPieceImage.size;
        addPieceButtonFrame.size.height = floor(self.topSwipeView.backView.bounds.size.height);
        addPieceButtonFrame.size.width = floor(addPieceButtonFrame.size.width);
        addPieceButton.frame = addPieceButtonFrame;
        
        [self.topSwipeView.backView addSubview:addPieceButton];
        
        // Delete Story Button
        UIButton *deleteStoryButton = [UIButton buttonWithType:UIButtonTypeCustom];        
        deleteStoryButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [deleteStoryButton setImage:_deleteStoryImage forState:UIControlStateNormal];
        [deleteStoryButton addTarget:self action:@selector(deleteStoryAlert:) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect deleteStoryButtonFrame = deleteStoryButton.bounds;
        deleteStoryButtonFrame.origin.x = floor(CGRectGetMaxX(addPieceButton.frame) + BUTTON_SPACING);
        deleteStoryButtonFrame.origin.y = floor(self.topSwipeView.backView.bounds.origin.y);
        deleteStoryButtonFrame.size = _deleteStoryImage.size;
        deleteStoryButtonFrame.size.height = floor(self.topSwipeView.backView.bounds.size.height);
        deleteStoryButtonFrame.size.width = floor(deleteStoryButtonFrame.size.width);
        deleteStoryButton.frame = deleteStoryButtonFrame;
        
        [self.topSwipeView.backView addSubview:deleteStoryButton];
        // Share Button
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];        
        shareButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [shareButton setImage:_shareWhiteImage forState:UIControlStateNormal];
        [shareButton addTarget:self.delegate action:@selector(shareStory:) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect shareButtonFrame = shareButton.bounds;
        shareButtonFrame.origin.x = floor(CGRectGetMaxX(deleteStoryButton.frame) + BUTTON_SPACING);
        shareButtonFrame.origin.y = floor(self.topSwipeView.backView.bounds.origin.y);
        shareButtonFrame.size = _shareWhiteImage.size;
        shareButtonFrame.size.height = floor(self.topSwipeView.backView.bounds.size.height);
        shareButtonFrame.size.width = floor(shareButtonFrame.size.width);
        shareButton.frame = shareButtonFrame;
        
        [self.topSwipeView.backView addSubview:shareButton];
    } else {
        assert(false);
    }
}

- (void) hideSwipedViewAnimated:(BOOL)animated
{
    [self.topSwipeView hideBackViewAnimated:animated inDirection:UISwipeGestureRecognizerDirectionRight];
}

- (void) revealSwipedViewAnimated:(BOOL)animated
{
    [self.topSwipeView revealBackViewAnimated:animated inDirection:UISwipeGestureRecognizerDirectionLeft];
}

- (void)backViewWillAppear:(BOOL)animated
{
    [self setupBackView];
}

- (void)backViewDidAppear:(BOOL)animated
{
    
}

- (void)backViewWillDisappear:(BOOL)animated
{
    
}

- (void)backViewDidDisappear:(BOOL)animated
{
	// Remove any subviews from the backView.
	[self.topSwipeView.backView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (BOOL)shouldSwipe
{
    return self.story.canContribute;
}

- (void) hideBackView:(UIButton *)button
{
    [self hideSwipedViewAnimated:YES];
}

- (void) showBackView:(UIButton *)button
{
    [self revealSwipedViewAnimated:YES];
}

#pragma mark UIAlertView
- (void)deleteStoryAlert:(UIButton *)button
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Story"
                                                        message:@"Do you want to delete this story?"
                                                       delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Delete Story"] && buttonIndex==1) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [self.delegate deleteStory:self];
    }
}
@end

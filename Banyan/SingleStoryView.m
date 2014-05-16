//
//  SingleStoryView.m
//  Banyan
//
//  Created by Devang Mundhra on 6/16/13.
//
//

#import "SingleStoryView.h"
#import "BanyanAppDelegate.h"
#import "Story+Permissions.h"
#import "User.h"
#import "Piece.h"
#import "BButton.h"
#import "AFBanyanAPIClient.h"

static NSString *const hideStoryString = @"Hide Story";
static NSString *const flagStoryString = @"Flag Story";
static NSString *const cancelUploadString = @"Cancel upload";
static NSString *const retryUploadString = @"Retry upload";

@interface SingleStoryView ()

@property (strong, nonatomic) BNSwipeableView *topSwipeView;
@property (strong, nonatomic) UIButton *storyFrontViewControl;
@property (strong, nonatomic) UILabel *storyAuthorsLabel;
@property (strong, nonatomic) BButton *storyUploadStatusButton;
@property (strong, nonatomic) UIButton *addPcButton;

@end

static UIImage *_clockSymbolImage;
static UIImage *_locationSymbolImage;
static UIImage *_backViewShowImage;
static UIImage *_backViewHideImage;
static UIImage *_shareBlackImage;
static UIImage *_shareWhiteImage;
static UIImage *_addPieceImage;
static UIImage *_flagStoryImage;
static UIImage *_flagStoryImageSelected;
static UIImage *_hideStoryImage;
static NSDateFormatter *_dateFormatter;
static UIFont *_boldFont;
static UIFont *_boldFontSmall;
static UIFont *_mediumFont;
static UIFont *_smallFont;
static UIFont *_thinFont;
static BOOL _loggedIn;
static NSString *_uploadString;
static NSString *_exclaimString;

@implementation SingleStoryView
@synthesize story = _story;
@synthesize storyFrontViewControl = _storyFrontViewControl;
@synthesize addPcButton = _addPcButton;
@synthesize delegate = _delegate;
@synthesize storyUploadStatusButton = _storyUploadStatusButton;

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
        _flagStoryImage = [UIImage imageNamed:@"Flag_Story"];
        _flagStoryImageSelected = [UIImage imageNamed:@"Flag_Story_selected"];
        _hideStoryImage = [UIImage imageNamed:@"hideStoryButton"];
        _shareWhiteImage = [UIImage imageNamed:@"shareButtonWhite"];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setDoesRelativeDateFormatting:YES];
        
        _boldFont = [UIFont fontWithName:@"Roboto-Bold" size:20];
        _boldFontSmall = [UIFont fontWithName:@"Roboto-Bold" size:16];
        _mediumFont = [UIFont fontWithName:@"Roboto-Medium" size:12];
        _smallFont = [UIFont fontWithName:@"Roboto-Medium" size:10];
        _thinFont = [UIFont fontWithName:@"Roboto-Thin" size:20];
        
        _loggedIn = [BanyanAppDelegate loggedIn];
        
        NSArray *fontAwesomeStrings = [NSString fa_allFontAwesomeStrings];
        _uploadString = [NSString fa_stringFromFontAwesomeStrings:fontAwesomeStrings forIcon:FAIconTime];
        _exclaimString = [NSString fa_stringFromFontAwesomeStrings:fontAwesomeStrings forIcon:FAIconExclamationSign];
        
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

#define SPACER_DISTANCE 3.0f

- (id)initWithFrame:(CGRect)frame
{
#define SIZE_OF_ADD_PC_BUTTON 36
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = YES;
        self.backgroundColor = BANYAN_WHITE_COLOR;
        [self.layer setCornerRadius:10.0f];
        [self.layer setMasksToBounds:YES];
        
        self.topSwipeView = [[BNSwipeableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), TOP_VIEW_HEIGHT)];
        self.topSwipeView.delegate = self;
        self.topSwipeView.opaque = YES;
        self.topSwipeView.backgroundColor = self.topSwipeView.frontView.backgroundColor = BANYAN_WHITE_COLOR;
        self.topSwipeView.backView.backgroundColor = BANYAN_DARKGRAY_COLOR;
        
        self.storyFrontViewControl = [UIButton buttonWithType:UIButtonTypeCustom];
        self.storyFrontViewControl.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        self.storyFrontViewControl.showsTouchWhenHighlighted = YES;
        [self.topSwipeView.frontView addSubview:self.storyFrontViewControl];
        [self addSubview:self.topSwipeView];
        
        [self setupFrontView];
        
        self.storyAuthorsLabel = [[UILabel alloc] initWithFrame:CGRectMake(TABLE_CELL_MARGIN,
                                                                           TOP_VIEW_HEIGHT + MIDDLE_VIEW_HEIGHT,
                                                                           CGRectGetWidth(frame) - 2*TABLE_CELL_MARGIN - SIZE_OF_ADD_PC_BUTTON - SPACER_DISTANCE,
                                                                           BOTTOM_VIEW_HEIGHT)];
        self.storyAuthorsLabel.backgroundColor = BANYAN_WHITE_COLOR;
        self.storyAuthorsLabel.textColor = [UIColor grayColor];
        self.storyAuthorsLabel.textAlignment = NSTextAlignmentLeft;
        self.storyAuthorsLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.storyAuthorsLabel.font = _mediumFont;
        [self addSubview:self.storyAuthorsLabel];
        
        self.storyUploadStatusButton = [[BButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.storyAuthorsLabel.frame) - SIZE_OF_ADD_PC_BUTTON,
                                                                                 TOP_VIEW_HEIGHT + MIDDLE_VIEW_HEIGHT + SPACER_DISTANCE,
                                                                                 SIZE_OF_ADD_PC_BUTTON,
                                                                                 BOTTOM_VIEW_HEIGHT - 2*SPACER_DISTANCE)
                                                                color:[UIColor bb_successColorV3]
                                                                style:BButtonStyleBootstrapV3
                                                                 icon:FAIconTime
                                                             fontSize:20.0f];
        [self.storyUploadStatusButton setTitle:_uploadString forState:UIControlStateNormal];
        [self.storyUploadStatusButton setColor:[UIColor bb_successColorV3]];
        [self.storyUploadStatusButton addTarget:self action:@selector(storyUploadActionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.storyUploadStatusButton.hidden = YES;
        [self.storyUploadStatusButton setTitleEdgeInsets:UIEdgeInsetsMake(SPACER_DISTANCE, 0, 0, 0)]; // Adjust this since title seems to be a little off from the top
        [self addSubview:self.storyUploadStatusButton];
        
        self.addPcButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.storyUploadStatusButton.frame) + SPACER_DISTANCE,
                                                                      TOP_VIEW_HEIGHT + MIDDLE_VIEW_HEIGHT + SPACER_DISTANCE,
                                                                      SIZE_OF_ADD_PC_BUTTON, BOTTOM_VIEW_HEIGHT - 2*SPACER_DISTANCE)];
        [self.addPcButton setTintColor:BANYAN_GREEN_COLOR];
        [self.addPcButton.titleLabel setFont:_thinFont];
        [self.addPcButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
        [self.addPcButton setTitleColor:BANYAN_DARK_GREEN_COLOR forState:UIControlStateNormal];
        self.addPcButton.showsTouchWhenHighlighted = YES;
        self.addPcButton.exclusiveTouch = YES;
        self.addPcButton.layer.borderColor = [BANYAN_GREEN_COLOR colorWithAlphaComponent:0.3].CGColor;
        self.addPcButton.layer.borderWidth = 1.0f;
        self.addPcButton.layer.cornerRadius = 5.0f;
        self.addPcButton.layer.masksToBounds = YES;
        
        [self insertSubview:self.addPcButton belowSubview:self.storyUploadStatusButton];
    }
    return self;
}

- (void)setStory:(Story *)story
{
    _story = story;
    [self.topSwipeView setNeedsDisplay];
    [self updateStoryLabels];
}

- (void)setDelegate:(id<SingleStoryViewDelegate>)delegate
{
    _delegate = delegate;
    [self.addPcButton addTarget:self.delegate action:@selector(addPiece:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) updateStoryLabels
{
    self.storyAuthorsLabel.text = [NSString stringWithFormat:@"by %@", [self.story shortStringOfContributors]];
    if (   [self.story.uploadStatusNumber unsignedIntegerValue] != RemoteObjectStatusSync) {
        if ([self.story.uploadStatusNumber unsignedIntegerValue] == RemoteObjectStatusPushing) {
            [self.storyUploadStatusButton setTitle:_uploadString forState:UIControlStateNormal];
            [self.storyUploadStatusButton setColor:[UIColor bb_successColorV3]];
        } else if ([self.story.uploadStatusNumber unsignedIntegerValue] == RemoteObjectStatusFailed) {
            [self.storyUploadStatusButton setTitle:_exclaimString forState:UIControlStateNormal];
            [self.storyUploadStatusButton setColor:[UIColor bb_dangerColorV3]];
        }
        if ([[AFBanyanAPIClient sharedClient] isReachable]) {
            self.storyUploadStatusButton.enabled = YES;
        } else {
            self.storyUploadStatusButton.enabled = NO;
        }
        self.storyUploadStatusButton.hidden = NO;
    } else {
        self.storyUploadStatusButton.hidden = YES;
    }

    if (self.story.canContribute && _loggedIn) {
        self.addPcButton.hidden = NO;
        if (self.story.isInvited) {
            [self.addPcButton setTitle:@"++" forState:UIControlStateNormal];
        } else {
            [self.addPcButton setTitle:@"+" forState:UIControlStateNormal];
        }
    }
    else {
        self.addPcButton.hidden = YES;
    }
}

- (IBAction)storyUploadActionButtonPressed:(id)sender
{
    BNLogInfo(@"story upload action button pressed for status %@", self.story.uploadStatusNumber);
    if ([self.story.uploadStatusNumber unsignedIntegerValue] == RemoteObjectStatusPushing) {
        [self cancelStoryUploadAlert:sender];
    } else if ([self.story.uploadStatusNumber unsignedIntegerValue] == RemoteObjectStatusFailed) {
        [self retryStoryUploadAlert:sender];
    }
}

# pragma mark BNSwipeableView delegates
- (void)drawFrontView:(CGRect)rect
{
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
    CGSize size, clockStringSize, locationStringSize;
    NSString *string;

    // Story title
    [BANYAN_BLACK_COLOR set];
    point = CGPointMake(TABLE_CELL_MARGIN, TABLE_CELL_MARGIN/2);
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    
    if (self.story.title.length <= 20) {
        [self.story.title drawInRect:CGRectMake(point.x, point.y, CGRectGetWidth(self.frame) - TABLE_CELL_MARGIN - BUTTON_SPACING, TOP_VIEW_HEIGHT)
                      withAttributes:@{NSFontAttributeName: _boldFont,
                                       NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                       NSParagraphStyleAttributeName: paraStyle}];
    } else {
        // Try to fit atleast a bit more if the story title is big
        [self.story.title drawInRect:CGRectMake(point.x, point.y, CGRectGetWidth(self.frame) - TABLE_CELL_MARGIN - BUTTON_SPACING, TOP_VIEW_HEIGHT)
                      withAttributes:@{NSFontAttributeName: _boldFontSmall,
                                       NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                       NSParagraphStyleAttributeName: paraStyle}];
    }
    
    // Time label
    point = CGPointMake(TABLE_CELL_MARGIN+_clockSymbolImage.size.width+SPACER_DISTANCE, TOP_VIEW_HEIGHT/2+SPACER_DISTANCE);
    [[UIColor grayColor] set];
    string = [_dateFormatter stringFromDate:self.story.createdAt];
    size = CGSizeMake(CGRectGetWidth(self.frame)/2 - TABLE_CELL_MARGIN - BUTTON_SPACING, TOP_VIEW_HEIGHT/2);
    
    paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineBreakMode = NSLineBreakByClipping;
    
    clockStringSize = [string boundingRectWithSize:size
                                        options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName: _mediumFont,
                                                  NSParagraphStyleAttributeName: paraStyle}
                                        context:nil].size;
    
    [string drawInRect:CGRectMake(point.x, point.y, floor(clockStringSize.width), TOP_VIEW_HEIGHT)
              withAttributes:@{NSFontAttributeName: _mediumFont,
                               NSForegroundColorAttributeName: [UIColor grayColor],
                               NSParagraphStyleAttributeName: paraStyle}];
    
    // Time image
    // Center image according to label
    point = CGPointMake(TABLE_CELL_MARGIN, floor(TOP_VIEW_HEIGHT/2 + (clockStringSize.height - _clockSymbolImage.size.height)/2)+SPACER_DISTANCE);
    [_clockSymbolImage drawAtPoint:point];
    
    locationStringSize = CGSizeZero;
    if ([self.story.location.name length]) {
        // Location label
        point.x = TABLE_CELL_MARGIN+_clockSymbolImage.size.width+SPACER_DISTANCE+clockStringSize.width+2*SPACER_DISTANCE+_locationSymbolImage.size.width+SPACER_DISTANCE;
        point.y = TOP_VIEW_HEIGHT/2+SPACER_DISTANCE;
        [[UIColor grayColor] set];
        string = self.story.location.name;
        size = CGSizeMake(CGRectGetWidth(self.frame)/2 - TABLE_CELL_MARGIN - BUTTON_SPACING, TOP_VIEW_HEIGHT/2);
        
        locationStringSize = [string boundingRectWithSize:size
                                               options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName: _mediumFont,
                                                         NSForegroundColorAttributeName: [UIColor grayColor],
                                                         NSParagraphStyleAttributeName: paraStyle}
                                               context:nil].size;
        
        [string drawInRect:CGRectMake(point.x, point.y, floor(locationStringSize.width), TOP_VIEW_HEIGHT)
            withAttributes:@{NSFontAttributeName: _mediumFont,
                             NSForegroundColorAttributeName: [UIColor grayColor],
                             NSParagraphStyleAttributeName: paraStyle}];
        
        // Location image
        // Center image according to label
        point = CGPointMake(TABLE_CELL_MARGIN+_clockSymbolImage.size.width+SPACER_DISTANCE+clockStringSize.width+2*SPACER_DISTANCE,
                            floor(TOP_VIEW_HEIGHT/2 + (locationStringSize.height - _locationSymbolImage.size.height)/2)+SPACER_DISTANCE);
        [_locationSymbolImage drawAtPoint:point];
    }
    
    // Number of pieces
    if (self.story.pieces.count) {
        point.x = TABLE_CELL_MARGIN+_clockSymbolImage.size.width+SPACER_DISTANCE+clockStringSize.width+2*SPACER_DISTANCE+_locationSymbolImage.size.width+SPACER_DISTANCE+locationStringSize.width+SPACER_DISTANCE;
        point.y = TOP_VIEW_HEIGHT/2+SPACER_DISTANCE;
        [[UIColor grayColor] set];
        NSUInteger unseenPieces = self.story.numNewPiecesToView;
        string = [NSString stringWithFormat:@"#%d pcs %@", self.story.pieces.count, unseenPieces == 0 ? @"" : [NSString stringWithFormat:@"(%d unread)", unseenPieces]];
        
        size = CGSizeMake(CGRectGetWidth(self.frame)/2 - TABLE_CELL_MARGIN - BUTTON_SPACING, TOP_VIEW_HEIGHT/2);
        
        size = [string boundingRectWithSize:size
                                    options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                 attributes:@{NSFontAttributeName: _mediumFont,
                                              NSForegroundColorAttributeName: [UIColor grayColor],
                                              NSParagraphStyleAttributeName: paraStyle}
                                    context:nil].size;
        
        [string drawInRect:CGRectMake(point.x, point.y, floor(size.width), TOP_VIEW_HEIGHT)
            withAttributes:@{NSFontAttributeName: _mediumFont,
                             NSForegroundColorAttributeName: [UIColor grayColor],
                             NSParagraphStyleAttributeName: paraStyle}];
    }
}

- (void) setupFrontView
{
    UIImage *frontViewControlImage = nil;
    // Have the reveal Backview button on front view
    frontViewControlImage = _backViewShowImage;
    [self.storyFrontViewControl addTarget:self action:@selector(toggleBackView:) forControlEvents:UIControlEventTouchUpInside];
    [self.storyFrontViewControl setImage:frontViewControlImage forState:UIControlStateNormal];
    // Set the button's frame
    CGRect frontViewControlButtonFrame;
    frontViewControlButtonFrame.size.width = floor(frontViewControlImage.size.width) + 2*TABLE_CELL_MARGIN;
    frontViewControlButtonFrame.origin.x = floor(CGRectGetWidth(self.topSwipeView.frame) - CGRectGetWidth(frontViewControlButtonFrame));
    frontViewControlButtonFrame.origin.y = floor(self.topSwipeView.frontView.frame.origin.y);
    frontViewControlButtonFrame.size.height = floor(self.topSwipeView.frontView.bounds.size.height);
    self.storyFrontViewControl.frame = frontViewControlButtonFrame;
}

- (void) setupBackView
{
    // Add Piece Button
    UIButton *flagStoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    // Make sure the button ends up in the right place when the cell is resized
    flagStoryButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    [flagStoryButton setImage:_flagStoryImage forState:UIControlStateNormal];
    [flagStoryButton setImage:_flagStoryImageSelected forState:UIControlStateHighlighted];
    [flagStoryButton addTarget:self action:@selector(flagStoryAlert:) forControlEvents:UIControlEventTouchUpInside];
    // Set the button's frame
    CGRect addPieceButtonFrame = flagStoryButton.bounds;
    addPieceButtonFrame.origin.x = TABLE_CELL_MARGIN + BUTTON_SPACING;
    addPieceButtonFrame.origin.y = floor(self.topSwipeView.backView.bounds.origin.y);
    addPieceButtonFrame.size = _addPieceImage.size;
    addPieceButtonFrame.size.height = floor(self.topSwipeView.backView.bounds.size.height);
    addPieceButtonFrame.size.width = floor(addPieceButtonFrame.size.width);
    flagStoryButton.frame = addPieceButtonFrame;
    [self.topSwipeView.backView addSubview:flagStoryButton];
    
    // Hide Story Button
    UIButton *hideStoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    hideStoryButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    
    [hideStoryButton setImage:_hideStoryImage forState:UIControlStateNormal];
    [hideStoryButton addTarget:self action:@selector(hideStoryAlert:) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect hideStoryButtonFrame = hideStoryButton.bounds;
    hideStoryButtonFrame.origin.x = floor(CGRectGetMaxX(flagStoryButton.frame) + BUTTON_SPACING);
    hideStoryButtonFrame.origin.y = floor(self.topSwipeView.backView.bounds.origin.y);
    hideStoryButtonFrame.size = _hideStoryImage.size;
    hideStoryButtonFrame.size.height = floor(self.topSwipeView.backView.bounds.size.height);
    hideStoryButtonFrame.size.width = floor(hideStoryButtonFrame.size.width);
    hideStoryButton.frame = hideStoryButtonFrame;
    if (!_loggedIn) {
        hideStoryButton.enabled = NO;
        hideStoryButton.alpha = 0.2;
    } else {
        hideStoryButton.enabled = YES;
        hideStoryButton.alpha = 1;
    }
    [self.topSwipeView.backView addSubview:hideStoryButton];
    // Share Button
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    shareButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    [shareButton setImage:_shareWhiteImage forState:UIControlStateNormal];
    [shareButton addTarget:self.delegate action:@selector(shareStory:) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect shareButtonFrame = shareButton.bounds;
    shareButtonFrame.origin.x = floor(CGRectGetMaxX(hideStoryButton.frame) + BUTTON_SPACING);
    shareButtonFrame.origin.y = floor(self.topSwipeView.backView.bounds.origin.y);
    shareButtonFrame.size = _shareWhiteImage.size;
    shareButtonFrame.size.height = floor(self.topSwipeView.backView.bounds.size.height);
    shareButtonFrame.size.width = floor(shareButtonFrame.size.width);
    shareButton.frame = shareButtonFrame;
    
    [self.topSwipeView.backView addSubview:shareButton];
}

- (void) toggleSwipeableViewAnimated:(BOOL)animated
{
    [self.topSwipeView toggleBackViewDisplay:animated];
}

- (void) hideSwipedViewAnimated:(BOOL)animated
{
    [self.topSwipeView hideBackViewAnimated:animated];
}

- (void) revealSwipedViewAnimated:(BOOL)animated
{
    [self.topSwipeView revealBackViewAnimated:animated];
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
    return YES;
}

- (void) toggleBackView:(UIButton *)button
{
    [self toggleSwipeableViewAnimated:YES];
}

#pragma mark UIAlertView
- (void)hideStoryAlert:(UIButton *)button
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:hideStoryString
                                                        message:@"Do you want to hide this story from your feed?"
                                                       delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    
    [alertView show];
}

- (void)flagStoryAlert:(UIButton *)button
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:flagStoryString
                                                        message:@"Do you want to report this story as inappropriate?\rYou can optionally specify a brief message for the reviewers."
                                                       delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [alertView show];
}

- (void)cancelStoryUploadAlert:(UIButton *)button
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:cancelUploadString
                                                        message:@"Do you want to cancel the upload of any changes to this story and its pieces?"
                                                       delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];    
    [alertView show];
}

- (void)retryStoryUploadAlert:(UIButton *)button
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:retryUploadString
                                                        message:@"Retry synchronization of any changes to this story and its pieces?"
                                                       delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:hideStoryString] && buttonIndex==1) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [self.delegate hideStory:self];
    } else if ([alertView.title isEqualToString:flagStoryString] && buttonIndex==1) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        NSString *message = [alertView textFieldAtIndex:0].text;
        [self.delegate flagStory:self withMessage:message];
    } else if ([alertView.title isEqualToString:cancelUploadString] && buttonIndex==1) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [self.story cancelAnyOngoingOperation];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"story upload action" label:@"cancel" value:nil];
    } else if ([alertView.title isEqualToString:retryUploadString] && buttonIndex==1) {
        [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [self.story uploadFailedRemoteObject];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"story upload action" label:@"retry" value:nil];
    }
}
@end

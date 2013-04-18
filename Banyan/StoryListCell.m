//
//  StoryListCell.m
//  Banyan
//
//  Created by Devang Mundhra on 3/18/13.
//
//

#import "StoryListCell.h"
#import "UIImage+ResizeAdditions.h"
#import "UIImage+RoundedCornerAdditions.h"
#import "UIImage+AlphaAdditions.h"
#import "UIImage+Create.h"
#import <QuartzCore/QuartzCore.h>
#import "StoryListCellMiddleViewController.h"
#import "BNImageLabel.h"

@implementation UIViewWithTopLine
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
    
    // Draw them with a 2.0 stroke width so they are a bit more visible.
    CGContextSetLineWidth(context, 2.0);
    
    CGContextMoveToPoint(context, 0, 0); //start at this point
    
    CGContextAddLineToPoint(context, CGRectGetMaxX(self.frame), 0); //draw to this point
    
    // and now draw the Path!
    CGContextStrokePath(context);
}
@end

@interface StoryListCell () {
    NSDateFormatter *dateFormatter;
}
@property (weak, nonatomic) IBOutlet UIView *containingView;
// Content View Properties
@property (weak, nonatomic) IBOutlet UISwipeableView *topSwipeableView;
@property (nonatomic, strong) IBOutlet UILabel *storyTitleLabel;
@property (nonatomic, strong) IBOutlet UIButton *storyFrontViewControl;
@property (nonatomic, strong) IBOutlet BNImageLabel *timeLabel;
@property (nonatomic, strong) IBOutlet BNImageLabel *locationLabel;

// Middle View Properties
@property (weak, nonatomic) IBOutlet UIViewWithTopLine *middleView;
@property (strong, nonatomic) IBOutlet StoryListCellMiddleViewController *middleVC;
@property (strong, nonatomic) UIGestureRecognizer *tapRecognizer;

// Bottom View Properties
@property (weak, nonatomic) IBOutlet UIViewWithTopLine *bottomView;
@property (nonatomic, strong) IBOutlet UILabel *storyTags;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation StoryListCell

@synthesize story = _story;
@synthesize topSwipeableView = _topSwipeableView;
@synthesize middleView = _middleView;
@synthesize bottomView = _bottomView;
@synthesize storyTitleLabel = _storyTitleLabel;
@synthesize storyFrontViewControl = _storyFrontViewControl;
@synthesize timeLabel = _timeLabel;
@synthesize locationLabel = _locationLabel;
@synthesize middleVC = _middleVC;
@synthesize tapRecognizer = _tapRecognizer;
@synthesize dateFormatter;
@synthesize containingView;
@synthesize storyTags = _storyTags;

#pragma mark setter/getters

- (StoryListCellMiddleViewController *)middleVC
{
    if (!_middleVC)
        _middleVC = [[StoryListCellMiddleViewController alloc] init];
    return _middleVC;
}

- (UIGestureRecognizer *)tapRecognizer
{
    if (!_tapRecognizer)
        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
    return _tapRecognizer;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)prepareForReuse
{
    // So that the cell does not show any image from before
    [super prepareForReuse];
    [self.storyFrontViewControl removeFromSuperview];
    [self.storyFrontViewControl removeTarget:nil
                       action:NULL
             forControlEvents:UIControlEventAllEvents];
    self.story = nil;
}

- (void)setHighlighted:(BOOL)highlighted {
	[self setHighlighted:highlighted animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
	[super setHighlighted:highlighted animated:animated];
	[self setNeedsDisplay];
}

- (void)setSelected:(BOOL)flag {
	[self setSelected:flag animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	[self setNeedsDisplay];
}

- (void) setup
{
    if (!dateFormatter)
        dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    
    [containingView.layer setCornerRadius:10.0f];
    [containingView.layer setMasksToBounds:YES];
    
    [self setupTopSwipeableFrontView];
    self.topSwipeableView.delegate = self;
    [self setupMiddleView];
    [self setupBottomView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setBackgroundColor:[UIColor clearColor]];
}

#pragma mark setter/getter functions

#define BUTTON_SPACING 20.0

- (void)setStory:(Story *)story
{
    _story = story;
    
    // Top View Setup
    self.storyTitleLabel.text = story.title;
    
    NSString *dateString = [dateFormatter stringFromDate:story.createdAt];
    self.timeLabel.label.text = dateString;
    
    if ([story.isLocationEnabled boolValue] && story.geocodedLocation) {
        // add the location information about the cells
        self.locationLabel.label.text = story.geocodedLocation;
        self.locationLabel.hidden = NO;
    } else {
        self.locationLabel.hidden = YES;
    }
    
    NSArray *tags = [story.tags componentsSeparatedByString:@","];
    self.storyTags.text = [tags componentsJoinedByString:@" "];
    
    if (story)
    {
        UIImage *frontViewControlImage = nil;
        if ([self.story.canContribute boolValue]) {
            // Have the reveal Backview button on front view
            frontViewControlImage = [UIImage imageNamed:@"backViewShowButton"];
            [self.storyFrontViewControl addTarget:self action:@selector(showBackView:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            // Just have the share button in front view.
            frontViewControlImage = [UIImage imageNamed:@"shareButtonBlack"];
            [self.storyFrontViewControl addTarget:self action:@selector(shareStory:) forControlEvents:UIControlEventTouchUpInside];
        }
        [self.storyFrontViewControl setImage:frontViewControlImage forState:UIControlStateNormal];
        // Set the button's frame
        CGRect frontViewControlButtonFrame = self.storyFrontViewControl.bounds;
        frontViewControlButtonFrame.origin.x = CGRectGetMaxX(self.topSwipeableView.frontView.bounds) - frontViewControlImage.size.width - BUTTON_SPACING;
        frontViewControlButtonFrame.origin.y = self.topSwipeableView.frontView.bounds.origin.y;
        frontViewControlButtonFrame.size = frontViewControlImage.size;
        frontViewControlButtonFrame.size.height = self.topSwipeableView.frontView.bounds.size.height;
        self.storyFrontViewControl.frame = frontViewControlButtonFrame;

        [self.topSwipeableView.frontView addSubview:self.storyFrontViewControl];
    }
    // Middle View Setup
    self.middleVC.story = story;
}

# pragma mark methods for Bottom View
- (void) setupBottomView
{
    CGRect aFrame = self.bottomView.bounds;
    aFrame.origin.y += 2;
    aFrame.origin.x += TABLE_CELL_MARGIN;
    aFrame.size.width -= 2*TABLE_CELL_MARGIN;
    aFrame.size.height -= 2*2;
    self.bottomView.backgroundColor = BANYAN_WHITE_COLOR;
    self.storyTags = [[UILabel alloc] initWithFrame:aFrame];
    self.storyTags.font = [UIFont fontWithName:@"Roboto-Medium" size:12];
    self.storyTags.textColor = [UIColor grayColor];
    [self.bottomView addSubview:self.storyTags];
}

# pragma mark methods for Middle View
- (void) setupMiddleView
{
    [self.middleView setBackgroundColor:BANYAN_WHITE_COLOR];
    [self.middleView addSubview:self.middleVC.view];
    [self.middleView addGestureRecognizer:self.tapRecognizer];
}

#pragma mark Tap Recognizer
- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    UITableView * tableView = (UITableView *)self.superview;
    id delegate = tableView.superview.nextResponder; // Hopefully this is a BNTableViewController.
    NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
    
    if ([delegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)]) {
        if ([(UITableViewController *)delegate tableView:tableView willSelectRowAtIndexPath:myIndexPath]) {
            [tableView selectRowAtIndexPath:myIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            if ([delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                [(UITableViewController *)delegate tableView:tableView didSelectRowAtIndexPath:myIndexPath];
            }
        }
    }
}

# pragma mark methods for Top View
- (void) setupTopSwipeableFrontView
{
    [self.topSwipeableView.frontView setBackgroundColor:[UIColor whiteColor]];
    [self.topSwipeableView.backView setBackgroundColor:BANYAN_DARKGRAY_COLOR];
    
    self.storyTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(TABLE_CELL_MARGIN, TABLE_CELL_MARGIN/2,
                                                                     self.topSwipeableView.frame.size.width - TABLE_CELL_MARGIN - BUTTON_SPACING,
                                                                     self.topSwipeableView.frame.size.height/2)];
    self.storyTitleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:20];
    self.storyTitleLabel.textColor = [UIColor blackColor];
    self.storyTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.storyTitleLabel.minimumFontSize = 15;
    [self.topSwipeableView.frontView addSubview:self.storyTitleLabel];
    
    UIImage *timeImage = [UIImage imageNamed:@"clockSymbol"];
    self.timeLabel = [[BNImageLabel alloc] initWithFrameAtOrigin:CGPointMake(TABLE_CELL_MARGIN, self.topSwipeableView.frame.size.height/2)
                                                       imageViewSize:timeImage.size
                                                           labelSize:CGSizeMake(self.topSwipeableView.frame.size.width/2 - 3*TABLE_CELL_MARGIN - 2*BUTTON_SPACING,
                                                                                self.topSwipeableView.frame.size.height/2)];
    [self.timeLabel.imageView setImage:timeImage];
    self.timeLabel.label.font = [UIFont fontWithName:@"Roboto-Medium" size:12];
    self.timeLabel.label.textColor = [UIColor grayColor];
    self.timeLabel.label.minimumFontSize = 10;
    self.timeLabel.label.textAlignment = NSTextAlignmentLeft;
    [self.topSwipeableView.frontView addSubview:self.timeLabel];
    
    UIImage *locationImage = [UIImage imageNamed:@"locationSymbolSmall"];
    self.locationLabel = [[BNImageLabel alloc] initWithFrameAtOrigin:CGPointMake(CGRectGetMaxX(self.timeLabel.frame) + 5, self.topSwipeableView.frame.size.height/2)
                                                       imageViewSize:locationImage.size
                                                           labelSize:CGSizeMake(self.topSwipeableView.frame.size.width/2 - TABLE_CELL_MARGIN - BUTTON_SPACING,
                                                                                self.topSwipeableView.frame.size.height/2)];
    [self.locationLabel.imageView setImage:locationImage];
    self.locationLabel.label.font = [UIFont fontWithName:@"Roboto-Medium" size:12];
    self.locationLabel.label.textColor = [UIColor grayColor];
    self.locationLabel.label.minimumFontSize = 10;
    self.locationLabel.label.textAlignment = NSTextAlignmentLeft;
    [self.topSwipeableView.frontView addSubview:self.locationLabel];
    
    self.storyFrontViewControl = [UIButton buttonWithType:UIButtonTypeCustom];
    self.storyFrontViewControl.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    
}

- (void) setupBackView
{
    if ([self.story.canContribute boolValue])
    {
        // Add backview control button
        UIButton *backViewControlButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *backViewControlImage = [UIImage imageNamed:@"backViewHideButton"];
        // Make sure the button ends up in the right place when the cell is resized
        backViewControlButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [backViewControlButton setImage:backViewControlImage forState:UIControlStateNormal];
        [backViewControlButton addTarget:self action:@selector(hideBackView:) forControlEvents:UIControlEventTouchUpInside];
        // Set the button's frame
        CGRect backViewControlButtonFrame = backViewControlButton.bounds;
        backViewControlButtonFrame.origin.x = 10;
        backViewControlButtonFrame.origin.y = self.topSwipeableView.backView.bounds.origin.y;
        backViewControlButtonFrame.size = backViewControlImage.size;
        backViewControlButtonFrame.size.height = self.topSwipeableView.backView.bounds.size.height;
        backViewControlButton.frame = backViewControlButtonFrame;
        
        [self.topSwipeableView.backView addSubview:backViewControlButton];
        
        // Add Piece Button
        UIButton *addPieceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *addPieceImage = [UIImage imageNamed:@"addPieceButton"];
        // Make sure the button ends up in the right place when the cell is resized
        addPieceButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [addPieceButton setImage:addPieceImage forState:UIControlStateNormal];
        [addPieceButton addTarget:self action:@selector(addPiece:) forControlEvents:UIControlEventTouchUpInside];
        // Set the button's frame
        CGRect addPieceButtonFrame = addPieceButton.bounds;
        addPieceButtonFrame.origin.x = CGRectGetMaxX(backViewControlButton.frame) + BUTTON_SPACING;;
        addPieceButtonFrame.origin.y = self.topSwipeableView.backView.bounds.origin.y;
        addPieceButtonFrame.size = addPieceImage.size;
        addPieceButtonFrame.size.height = self.topSwipeableView.backView.bounds.size.height;
        addPieceButton.frame = addPieceButtonFrame;
        
        [self.topSwipeableView.backView addSubview:addPieceButton];
        
        // Delete Story Button
        UIButton *deleteStoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *deleteStoryImage = [UIImage imageNamed:@"deleteStoryButton"];

        deleteStoryButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [deleteStoryButton setImage:deleteStoryImage forState:UIControlStateNormal];
        [deleteStoryButton addTarget:self action:@selector(deleteStoryAlert:) forControlEvents:UIControlEventTouchUpInside];

        CGRect deleteStoryButtonFrame = deleteStoryButton.bounds;
        deleteStoryButtonFrame.origin.x = CGRectGetMaxX(addPieceButton.frame) + BUTTON_SPACING;
        deleteStoryButtonFrame.origin.y = self.topSwipeableView.backView.bounds.origin.y;
        deleteStoryButtonFrame.size = deleteStoryImage.size;
        deleteStoryButtonFrame.size.height = self.topSwipeableView.backView.bounds.size.height;
        deleteStoryButton.frame = deleteStoryButtonFrame;
        
        [self.topSwipeableView.backView addSubview:deleteStoryButton];
        // Share Button
        UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *shareButtonImage = [UIImage imageNamed:@"shareButtonWhite"];
        
        shareButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        [shareButton setImage:shareButtonImage forState:UIControlStateNormal];
        [shareButton addTarget:self action:@selector(shareStory:) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect shareButtonFrame = shareButton.bounds;
        shareButtonFrame.origin.x = CGRectGetMaxX(deleteStoryButton.frame) + BUTTON_SPACING;
        shareButtonFrame.origin.y = self.topSwipeableView.backView.bounds.origin.y;
        shareButtonFrame.size = shareButtonImage.size;
        shareButtonFrame.size.height = self.topSwipeableView.backView.bounds.size.height;
        shareButton.frame = shareButtonFrame;
        
        [self.topSwipeableView.backView addSubview:shareButton];
    } else {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.topSwipeableView.bounds.size.width, 30)];
        label.font = [UIFont systemFontOfSize:15];
        label.text = @"You do not have permission to modify this story";
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = BANYAN_BROWN_COLOR;
        [label.layer setCornerRadius:4];
        
        [self.topSwipeableView.backView addSubview:label];
    }
}

#pragma mark UISwipeableViewDelegate methods

- (BOOL)shouldSwipe
{
    return [self.story.canContribute boolValue];
}

- (void)didSwipe
{
    
}

- (void) hideSwipedViewAnimated:(BOOL)animated
{
    [self.topSwipeableView hideBackViewAnimated:animated inDirection:UISwipeGestureRecognizerDirectionRight];
}

- (void) revealSwipedViewAnimated:(BOOL)animated
{
    [self.topSwipeableView revealBackViewAnimated:animated inDirection:UISwipeGestureRecognizerDirectionLeft];
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
	[self.topSwipeableView.backView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)drawBackView:(CGRect)rect
{
//	[[UIImage imageNamed:@"dotted-pattern.png"] drawAsPatternInRect:rect];
//	[self drawShadowsWithHeight:10 opacity:0.3 InRect:rect forContext:UIGraphicsGetCurrentContext()];
}

- (void)drawShadowsWithHeight:(CGFloat)shadowHeight opacity:(CGFloat)opacity InRect:(CGRect)rect forContext:(CGContextRef)context {
	
	CGColorSpaceRef space = CGBitmapContextGetColorSpace(context);
	
	CGFloat topComponents[8] = {0, 0, 0, opacity, 0, 0, 0, 0};
	CGGradientRef topGradient = CGGradientCreateWithColorComponents(space, topComponents, nil, 2);
	CGPoint finishTop = CGPointMake(rect.origin.x, rect.origin.y + shadowHeight);
	CGContextDrawLinearGradient(context, topGradient, rect.origin, finishTop, kCGGradientDrawsAfterEndLocation);
	
	CGFloat bottomComponents[8] = {0, 0, 0, 0, 0, 0, 0, opacity};
	CGGradientRef bottomGradient = CGGradientCreateWithColorComponents(space, bottomComponents, nil, 2);
	CGPoint startBottom = CGPointMake(rect.origin.x, rect.size.height - shadowHeight);
	CGPoint finishBottom = CGPointMake(rect.origin.x, rect.size.height);
	CGContextDrawLinearGradient(context, bottomGradient, startBottom, finishBottom, kCGGradientDrawsAfterEndLocation);
	
	CGGradientRelease(topGradient);
	CGGradientRelease(bottomGradient);
}

#pragma mark back view methods
- (void)addPiece:(UIButton *)button
{
    UITableView * tableView = (UITableView *)self.superview;
    id delegate = tableView.superview.nextResponder; // Hopefully this is a BNTableViewController.
    NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
    
    if ([delegate respondsToSelector:@selector(addPieceForRowAtIndexPath:)]) {
        [delegate performSelector:@selector(addPieceForRowAtIndexPath:) withObject:myIndexPath];
    }
}

- (void)deleteStoryAlert:(UIButton *)button
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Story"
                                                        message:@"Do you want to delete this story?"
                                                       delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    
    [alertView show];
}

- (void)deleteStory
{
    UITableView * tableView = (UITableView *)self.superview;
    id delegate = tableView.superview.nextResponder; // Hopefully this is a BNTableViewController.
    NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
    
    if ([delegate respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
        [delegate tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:myIndexPath];
    }
}

- (void) shareStory:(UIButton *)button
{
    UITableView * tableView = (UITableView *)self.superview;
    id delegate = tableView.superview.nextResponder; // Hopefully this is a BNTableViewController.
    NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
    
    if ([delegate respondsToSelector:@selector(shareStoryAtIndexPath:)]) {
        [delegate performSelector:@selector(shareStoryAtIndexPath:) withObject:myIndexPath];
    }
}

- (void) hideBackView:(UIButton *)button
{
    [self hideSwipedViewAnimated:YES];
}

- (void) showBackView:(UIButton *)button
{
    [self revealSwipedViewAnimated:YES];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Delete Story"] && buttonIndex==1) {
        [self deleteStory];
    }
}

@end

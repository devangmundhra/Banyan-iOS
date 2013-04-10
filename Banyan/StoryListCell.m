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

@interface StoryListCell ()
// Content View Properties
@property (weak, nonatomic) IBOutlet UISwipeableView *topSwipeableView;
@property (nonatomic, strong) IBOutlet UILabel *storyTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *storyLocationLabel;
@property (nonatomic, strong) IBOutlet UIButton *storyFrontViewControl;

// Middle View Properties
@property (weak, nonatomic) IBOutlet UIView *middleView;
@property (strong, nonatomic) IBOutlet StoryListCellMiddleViewController *middleVC;
@property (strong, nonatomic) UIGestureRecognizer *tapRecognizer;

// Bottom View Properties
@property (weak, nonatomic) IBOutlet UIView *bottomView;

@end

@implementation StoryListCell

@synthesize story = _story;
@synthesize topSwipeableView = _topSwipeableView;
@synthesize middleView = _middleView;
@synthesize bottomView = _bottomView;
@synthesize storyTitleLabel = _storyTitleLabel;
@synthesize storyLocationLabel = _storyLocationLabel;
@synthesize storyFrontViewControl = _storyFrontViewControl;
@synthesize middleVC = _middleVC;
@synthesize tapRecognizer = _tapRecognizer;

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
    [self setupTopSwipeableFrontView];
    self.topSwipeableView.delegate = self;
    [self setupMiddleView];
    [self setupBottomView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setBackgroundColor:BANYAN_WHITE_COLOR];
}

#pragma mark setter/getter functions

#define BUTTON_SPACING 20.0

- (void)setStory:(Story *)story
{
    _story = story;
    
    // Top View Setup
    self.storyTitleLabel.text = story.title;
    self.storyTitleLabel.font = [UIFont fontWithName:STORY_FONT size:16];
    
    self.storyTitleLabel.textColor = [UIColor blackColor];
    self.storyLocationLabel.textColor = [UIColor grayColor];
    
    if ([story.isLocationEnabled boolValue] && ![story.geocodedLocation isEqual:[NSNull null]]) {
        // add the location information about the cells
        self.storyLocationLabel.text = story.geocodedLocation;
    }
    
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
        frontViewControlButtonFrame.origin.x = CGRectGetMaxX(self.topSwipeableView.frontView.frame) - frontViewControlImage.size.width - BUTTON_SPACING;
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
}

# pragma mark methods for Middle View
- (void) setupMiddleView
{
    [self.middleView setBackgroundColor:BANYAN_GREEN_COLOR];
    [self.middleView addSubview:self.middleVC.view];
    [self.middleView addGestureRecognizer:self.tapRecognizer];
}

#pragma mark Tap Recognizer
- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    UITableView * tableView = (UITableView *)self.superview;
    id delegate = tableView.nextResponder; // Hopefully this is a UITableViewController.
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
                                                                     self.topSwipeableView.frame.size.width - TABLE_CELL_MARGIN,
                                                                     self.topSwipeableView.frame.size.height - 2 * TABLE_CELL_MARGIN)];
    self.storyTitleLabel.font = [UIFont systemFontOfSize:12.0];
    self.storyTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.storyTitleLabel.minimumFontSize = 12;
    self.storyTitleLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.storyTitleLabel];
    [self.topSwipeableView.frontView addSubview:self.storyTitleLabel];
    
    self.storyLocationLabel = [[UILabel alloc] initWithFrame:CGRectMake(TABLE_CELL_MARGIN, TABLE_CELL_MARGIN/2 + 15,
                                                                        self.topSwipeableView.frame.size.width - TABLE_CELL_MARGIN,
                                                                        self.topSwipeableView.frame.size.height - 2 * TABLE_CELL_MARGIN)];
    self.storyLocationLabel.font = [UIFont systemFontOfSize:12];
    self.storyLocationLabel.textColor = [UIColor whiteColor];
    self.storyLocationLabel.minimumFontSize = 10;
    self.storyLocationLabel.textAlignment = NSTextAlignmentLeft;
    self.storyLocationLabel.backgroundColor = [UIColor clearColor];
    [self.topSwipeableView.frontView addSubview:self.storyLocationLabel];
    
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
    id delegate = tableView.nextResponder; // Hopefully this is a UITableViewController.
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
    id delegate = tableView.nextResponder; // Hopefully this is a UITableViewController.
    NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
    
    if ([delegate respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
        [delegate tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:myIndexPath];
    }
}

- (void) shareStory:(UIButton *)button
{
    UITableView * tableView = (UITableView *)self.superview;
    id delegate = tableView.nextResponder; // Hopefully this is a UITableViewController.
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

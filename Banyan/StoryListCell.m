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
    [self setupTopSwipeableContentView];
    self.topSwipeableView.delegate = self;
    [self setupMiddleView];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setBackgroundColor:[UIColor clearColor]];
}

- (void)prepareForReuse
{
    // So that the cell does not show any image from before
    [super prepareForReuse];
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

#pragma mark setter/getter functions

- (void)setStory:(Story *)story
{
    _story = story;
    self.storyTitleLabel.text = story.title;
    self.storyTitleLabel.font = [UIFont fontWithName:STORY_FONT size:16];
    
    self.storyTitleLabel.textColor = [UIColor blackColor];
    self.storyLocationLabel.textColor = [UIColor grayColor];
    
    if (story.isLocationEnabled && ![story.geocodedLocation isEqual:[NSNull null]]) {
        // add the location information about the cells
        self.storyLocationLabel.text = story.geocodedLocation;
    }
    
    // Middle View Setup
    self.middleVC.story = story;
}

# pragma mark methods for Bottom View

# pragma mark methods for Middle View
- (void) setupMiddleView
{
    [self.middleView setBackgroundColor:[UIColor clearColor]];
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
- (void) setupTopSwipeableContentView
{
    [self.topSwipeableView.contentView setBackgroundColor:[UIColor whiteColor]];
    self.storyTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(TABLE_CELL_MARGIN, TABLE_CELL_MARGIN/2,
                                                                     self.topSwipeableView.frame.size.width - TABLE_CELL_MARGIN,
                                                                     self.topSwipeableView.frame.size.height - 2 * TABLE_CELL_MARGIN)];
    self.storyTitleLabel.font = [UIFont systemFontOfSize:12.0];
    self.storyTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.storyTitleLabel.minimumFontSize = 12;
    self.storyTitleLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.storyTitleLabel];
    [self.topSwipeableView.contentView addSubview:self.storyTitleLabel];
    
    self.storyLocationLabel = [[UILabel alloc] initWithFrame:CGRectMake(TABLE_CELL_MARGIN, TABLE_CELL_MARGIN/2 + 15,
                                                                        self.topSwipeableView.frame.size.width - TABLE_CELL_MARGIN,
                                                                        self.topSwipeableView.frame.size.height - 2 * TABLE_CELL_MARGIN)];
    self.storyLocationLabel.font = [UIFont systemFontOfSize:12];
    self.storyLocationLabel.textColor = [UIColor whiteColor];
    self.storyLocationLabel.minimumFontSize = 10;
    self.storyLocationLabel.textAlignment = NSTextAlignmentLeft;
    self.storyLocationLabel.backgroundColor = [UIColor clearColor];
    [self.topSwipeableView.contentView addSubview:self.storyLocationLabel];
}

- (void) setupBackView
{
#define BUTTON_LEFT_MARGIN 10.0
#define BUTTON_SPACING 80.0
    if (self.story.canContribute)
    {
        NSArray *buttonData = [NSArray arrayWithObjects:
                               [NSDictionary dictionaryWithObjectsAndKeys:@"Add-Scene", @"title", @"addScene:", @"selector", [UIColor colorWithRed:44/255.0 green:127/255.0 blue:84/255.0 alpha:1], @"color", nil],
                               [NSDictionary dictionaryWithObjectsAndKeys:@"Delete-Story", @"title", @"deleteStoryAlert:", @"selector", [UIColor redColor], @"color", nil],
                               nil];
        
        // Iterate through the button data and create a button for each entry
        CGFloat leftEdge = BUTTON_LEFT_MARGIN;
        for (NSDictionary* buttonInfo in buttonData)
        {
            // Create the button
            UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
            
            // Make sure the button ends up in the right place when the cell is resized
            button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
            
            // Get the button image
            UIImage* buttonImage = [UIImage imageFromText:[buttonInfo objectForKey:@"title"] withSize:16];
            
            // Set the button's frame
            button.frame = CGRectMake(leftEdge, self.topSwipeableView.backView.center.y - buttonImage.size.height/2.0, buttonImage.size.width, buttonImage.size.height);
            
            // Add the image as the button's background image
            UIImage* colorImage = [UIImage imageFilledWith:[UIColor whiteColor] using:buttonImage];
            [button setImage:colorImage forState:UIControlStateNormal];
            UIImage* backgroundImage = [UIImage imageWithColor:[buttonInfo objectForKey:@"color"] forRect:CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
            [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
            UIImage* bkgHighlightedImage = [UIImage imageWithColor:[UIColor brownColor] forRect:CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
            [button setBackgroundImage:bkgHighlightedImage forState:UIControlStateSelected];
            
            // Add a touch up inside action
            [button addTarget:self action:NSSelectorFromString([buttonInfo objectForKey:@"selector"]) forControlEvents:UIControlEventTouchUpInside];
            
            // Add the button to the side swipe view
            [self.topSwipeableView.backView addSubview:button];
            
            // Move the left edge in prepartion for the next button
            leftEdge = leftEdge + buttonImage.size.width + BUTTON_SPACING;
        }
    } else {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.frame.size.width, TABLE_ROW_HEIGHT-30)];
        label.font = [UIFont systemFontOfSize:15];
        label.text = @"You do not have permission to modify this story";
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor colorWithRed:136/255.0 green:103/255.0 blue:68/255.0 alpha:1];
        [label.layer setCornerRadius:4];
        
        [self.topSwipeableView.backView addSubview:label];
    }
}

#pragma mark UISwipeableViewDelegate methods
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

- (void)backViewDidDisappear:(BOOL)animated
{
	// Remove any subviews from the backView.
	[self.topSwipeableView.backView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)drawBackView:(CGRect)rect
{
	[[UIImage imageNamed:@"dotted-pattern.png"] drawAsPatternInRect:rect];
	[self drawShadowsWithHeight:10 opacity:0.3 InRect:rect forContext:UIGraphicsGetCurrentContext()];
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
- (void)addScene:(UIButton *)button
{
    UITableView * tableView = (UITableView *)self.superview;
    id delegate = tableView.nextResponder; // Hopefully this is a UITableViewController.
    NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
    
    if ([delegate respondsToSelector:@selector(addSceneForRowAtIndexPath:)]) {
        [delegate performSelector:@selector(addSceneForRowAtIndexPath:) withObject:myIndexPath];
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

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Delete Story"] && buttonIndex==1) {
        [self deleteStory];
    }
}

@end

//
//  StoryListStoryCell.m
//  Storied
//
//  Created by Devang Mundhra on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryListStoryCell.h"

@implementation StoryListStoryCell

@synthesize storyTitleLabel = _storyTitleLabel;
@synthesize storyImageView = _storyImageView;
@synthesize storyLocationLabel = _storyLocationLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupContentView];
    }
    return self;
}

- (void) setupContentView
{
    // Initialization code
    self.storyImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y,
                                                                    self.frame.size.width, TABLE_ROW_HEIGHT)];
    self.storyImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.storyImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.storyImageView];
    
    self.storyTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(TABLE_CELL_MARGIN, TABLE_CELL_MARGIN,
                                                                 self.frame.size.width - 2 * TABLE_CELL_MARGIN,
                                                                 self.frame.size.height - 2 * TABLE_CELL_MARGIN)];
    self.storyTitleLabel.font = [UIFont systemFontOfSize:17.0];
    self.storyTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.storyTitleLabel.minimumFontSize = 12;
    self.storyTitleLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.storyTitleLabel];
    
    self.storyLocationLabel = [[UILabel alloc] initWithFrame:CGRectMake(TABLE_CELL_MARGIN,
                                                                    self.frame.origin.y + TABLE_ROW_HEIGHT - 2 * TABLE_CELL_MARGIN,
                                                                    self.frame.size.width - 2 * TABLE_CELL_MARGIN, TABLE_CELL_MARGIN)];
    self.storyLocationLabel.font = [UIFont systemFontOfSize:12];
    self.storyLocationLabel.textColor = [UIColor whiteColor];
    self.storyLocationLabel.minimumFontSize = 10;
    self.storyLocationLabel.textAlignment = UITextAlignmentRight;
    self.storyLocationLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.storyLocationLabel];
}

- (void) setupBackView
{
#define BUTTON_LEFT_MARGIN 10.0
#define BUTTON_SPACING 80.0
    NSArray *buttonData = [NSArray arrayWithObjects:
                           [NSDictionary dictionaryWithObjectsAndKeys:@"Add-Scene", @"title", @"addScene:", @"selector", [UIColor colorWithWhite:0.9 alpha:1.0], @"color", nil],
                           [NSDictionary dictionaryWithObjectsAndKeys:@"Delete-Story", @"title", @"deleteStory:", @"selector", [UIColor redColor], @"color", nil],
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
        UIImage* buttonImage = [UIImage imageFromText:[buttonInfo objectForKey:@"title"]];
        
        // Set the button's frame
        button.frame = CGRectMake(leftEdge, self.backView.center.y - buttonImage.size.height/2.0, buttonImage.size.width, buttonImage.size.height);
        
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
        [self.backView addSubview:button];
        
        // Move the left edge in prepartion for the next button
        leftEdge = leftEdge + buttonImage.size.width + BUTTON_SPACING;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    // So that the cell does not show any image from before
    [super prepareForReuse];
    self.storyImageView.image = nil;
    [self.storyImageView cancelImageRequestOperation];
}

- (void)addScene:(UIButton *)button
{
    UITableView * tableView = (UITableView *)self.superview;
    NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
    id delegate = tableView.nextResponder; // Hopefully this is a TISwipeableTableViewController.
    
    if ([delegate respondsToSelector:@selector(addSceneForRowAtIndexPath:)]) {
        [delegate performSelector:@selector(addSceneForRowAtIndexPath:) withObject:myIndexPath];
    }
}

- (void)deleteStory:(UIButton *)button
{
    UITableView * tableView = (UITableView *)self.superview;
    NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
    id delegate = tableView.nextResponder; // Hopefully this is a TISwipeableTableViewController.
    
    if ([delegate respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
        [delegate tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:myIndexPath];
    }
}

#pragma mark TISwipeableTableViewCell
- (void)backViewWillAppear:(BOOL)animated
{
    [self setupBackView];
}

- (void)backViewDidDisappear:(BOOL)animated
{
	// Remove any subviews from the backView.
	[self.backView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)drawContentView:(CGRect)rect
{
	[contentView addSubview:self.contentView];
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

@end

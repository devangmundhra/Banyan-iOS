//
//  TISwipeableTableView.m
//  TISwipeableTableView
//
//  Created by Tom Irving on 28/05/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TISwipeableTableView.h"
#import <QuartzCore/QuartzCore.h>

//==========================================================
// - TISwipeableTableViewController
//==========================================================

@interface TISwipeableTableViewController ()
@property (nonatomic, strong) NSIndexPath *indexOfVisibleBackView;
@end

@implementation TISwipeableTableViewController
@synthesize indexOfVisibleBackView;
@synthesize swipeDirection;

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return ([indexPath compare:indexOfVisibleBackView] == NSOrderedSame) ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self hideVisibleBackView:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldSwipeCellAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView didSwipeCellAtIndexPath:(NSIndexPath *)indexPath {

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self hideVisibleBackView:YES];
}

- (void)revealBackViewAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
	
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	[self hideVisibleBackView:animated];
	
	if ([cell respondsToSelector:@selector(revealBackViewAnimated:inDirection:)]){
		[(TISwipeableTableViewCell *)cell revealBackViewAnimated:animated inDirection:UISwipeGestureRecognizerDirectionRight];
        [self setIndexOfVisibleBackView:indexPath];
	}
}

- (void)hideVisibleBackView:(BOOL)animated {
	
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexOfVisibleBackView];
	if ([cell respondsToSelector:@selector(hideBackViewAnimated:inDirection:)]) {
		[(TISwipeableTableViewCell *)cell hideBackViewAnimated:animated inDirection:swipeDirection];
        [self setIndexOfVisibleBackView:nil];
	}
}

@end

//==========================================================
// - TISwipeableTableViewCell
//==========================================================

@implementation TISwipeableTableViewCellView
- (void)drawRect:(CGRect)rect {
	[(TISwipeableTableViewCell *)self.superview drawContentView:rect];
}
@end

@implementation TISwipeableTableViewCellBackView
- (void)drawRect:(CGRect)rect {
	[(TISwipeableTableViewCell *)self.superview drawBackView:rect];
}

@end

@interface TISwipeableTableViewCell (Private)
- (void)initialSetup;
- (void)resetViews:(BOOL)animated;
@end

@implementation TISwipeableTableViewCell
@synthesize backView;
@synthesize contentViewMoving;
@synthesize shouldBounce;

#pragma mark - Init / Overrides
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
		[self initialSetup];
    }
	
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [super initWithCoder:aDecoder])){
		[self initialSetup];
	}
	
	return self;
}

- (void)initialSetup {
	
	[self setBackgroundColor:[UIColor clearColor]];
	
	contentView = [[TISwipeableTableViewCellView alloc] initWithFrame:CGRectZero];
	[contentView setClipsToBounds:YES];
	[contentView setOpaque:YES];
	[contentView setBackgroundColor:[UIColor clearColor]];
	
	UISwipeGestureRecognizer * frontSwipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(frontViewWasSwipedRight:)];
	[frontSwipeRecognizerRight setDirection:UISwipeGestureRecognizerDirectionRight];
    UISwipeGestureRecognizer * frontSwipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(frontViewWasSwipedLeft:)];
	[frontSwipeRecognizerLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [contentView addGestureRecognizer:frontSwipeRecognizerRight];
	[contentView addGestureRecognizer:frontSwipeRecognizerLeft];
	
	backView = [[TISwipeableTableViewCellBackView alloc] initWithFrame:CGRectZero];
	[backView setOpaque:YES];
	[backView setClipsToBounds:YES];
	[backView setHidden:YES];
	[backView setBackgroundColor:[UIColor clearColor]];
    
	UISwipeGestureRecognizer * backSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(backViewWasSwiped:)];
    // The direction of backview swipe depends on how it was revealed
	[backSwipeRecognizer setDirection:(UISwipeGestureRecognizerDirectionRight |
                                       UISwipeGestureRecognizerDirectionLeft)];
	[backView addGestureRecognizer:backSwipeRecognizer];
	
	[self addSubview:backView];
	[self addSubview:contentView];
	
	contentViewMoving = NO;
	shouldBounce = YES;
	oldStyle = self.selectionStyle;
}

- (void)prepareForReuse {
	
	[self resetViews:NO];
	[super prepareForReuse];
}

- (void)setFrame:(CGRect)aFrame {
	
	[super setFrame:aFrame];
	
	CGRect newBounds = self.bounds;
	newBounds.size.height -= 1;
	[backView setFrame:newBounds];	
	[contentView setFrame:newBounds];
}

- (void)setNeedsDisplay {
	
	[super setNeedsDisplay];
	if (!contentView.hidden) [contentView setNeedsDisplay];
	if (!backView.hidden) [backView setNeedsDisplay];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType {
	// Having an accessory buggers swiping right up, so we override.
	// It's easier just to draw the accessory yourself.
}

- (void)setAccessoryView:(UIView *)accessoryView {
	// Same as above.
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

#pragma mark - Subclass Methods
// Implement the following in a subclass
- (void)drawContentView:(CGRect)rect {
	
}

- (void)drawBackView:(CGRect)rect {
	
}

// Optional implementation
- (void)backViewWillAppear:(BOOL)animated {
	
}

- (void)backViewDidAppear:(BOOL)animated {
	
}

- (void)backViewWillDisappear:(BOOL)animated {
	
}

- (void)backViewDidDisappear:(BOOL)animated {
	
}

//===============================//

#pragma mark - Back View Show / Hide
- (void)frontViewWasSwipedRight:(UISwipeGestureRecognizer *)recognizer
{
	UITableView * tableView = (UITableView *)self.superview;
	id delegate = tableView.nextResponder; // Hopefully this is a TISwipeableTableViewController.
	
	if ([delegate respondsToSelector:@selector(tableView:shouldSwipeCellAtIndexPath:)]){
		
		NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
		
		if ([delegate tableView:tableView shouldSwipeCellAtIndexPath:myIndexPath]){
            if ([delegate respondsToSelector:@selector(hideVisibleBackView:)])
                [delegate hideVisibleBackView:YES];
			[self revealBackViewAnimated:YES inDirection:UISwipeGestureRecognizerDirectionRight];
            if ([delegate respondsToSelector:@selector(setIndexOfVisibleBackView:)]) {
                [delegate setIndexOfVisibleBackView:myIndexPath];
                [delegate setSwipeDirection:UISwipeGestureRecognizerDirectionRight];
            }
			if ([delegate respondsToSelector:@selector(tableView:didSwipeCellAtIndexPath:)]){
				[delegate tableView:tableView didSwipeCellAtIndexPath:myIndexPath];
			}
		}
	}
}
- (void)frontViewWasSwipedLeft:(UISwipeGestureRecognizer *)recognizer
{
	UITableView * tableView = (UITableView *)self.superview;
	id delegate = tableView.nextResponder; // Hopefully this is a TISwipeableTableViewController.
	
	if ([delegate respondsToSelector:@selector(tableView:shouldSwipeCellAtIndexPath:)]){
		
		NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
		
		if ([delegate tableView:tableView shouldSwipeCellAtIndexPath:myIndexPath]){
            if ([delegate respondsToSelector:@selector(hideVisibleBackView:)])
                [delegate hideVisibleBackView:YES];
			[self revealBackViewAnimated:YES inDirection:UISwipeGestureRecognizerDirectionLeft];
			if ([delegate respondsToSelector:@selector(setIndexOfVisibleBackView:)]) {
                [delegate setIndexOfVisibleBackView:myIndexPath];
                [delegate setSwipeDirection:UISwipeGestureRecognizerDirectionLeft];
            }
			if ([delegate respondsToSelector:@selector(tableView:didSwipeCellAtIndexPath:)]){
				[delegate tableView:tableView didSwipeCellAtIndexPath:myIndexPath];
			}
		}
	}
}

- (void)backViewWasSwiped:(UISwipeGestureRecognizer *)recognizer
{
    UITableView * tableView = (UITableView *)self.superview;
	id delegate = tableView.nextResponder; // Hopefully this is a TISwipeableTableViewController.
    
    [self hideBackViewAnimated:YES inDirection:[delegate swipeDirection]];
    if ([delegate respondsToSelector:@selector(setIndexOfVisibleBackView:)]) {
        [delegate setIndexOfVisibleBackView:nil];
    }
}

- (void)revealBackViewAnimated:(BOOL)animated inDirection:(UISwipeGestureRecognizerDirection)direction
{
	if (!contentViewMoving && backView.hidden){
		
		contentViewMoving = YES;
		
		[backView.layer setHidden:NO];
		[backView setNeedsDisplay];
		
		[self backViewWillAppear:animated];
		
		oldStyle = self.selectionStyle;
		[self setSelectionStyle:UITableViewCellSelectionStyleNone];

		if (animated) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            
            if (direction == UISwipeGestureRecognizerDirectionRight) {
                [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                [contentView.layer setPosition:CGPointMake(contentView.frame.size.width, contentView.layer.position.y)];
            } else {
                [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                [contentView.layer setPosition:CGPointMake(-contentView.frame.size.width, contentView.layer.position.y)];
            }
            [UIView setAnimationDelegate:self];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            [UIView setAnimationDidStopSelector:@selector(animationDidStopAddingBackView:finished:context:)];
            [UIView commitAnimations];
		}
		else
		{
			[self backViewDidAppear:animated];
			[self setSelected:NO];
			
			contentViewMoving = NO;
		}
	}
}

#define BOUNCE_PIXELS 20.0

- (void)hideBackViewAnimated:(BOOL)animated inDirection:(UISwipeGestureRecognizerDirection)direction
{
	
	if (!contentViewMoving && !backView.hidden){
		
		contentViewMoving = YES;
		
		[self backViewWillDisappear:animated];
		
		if (animated) {
            // The first step in a bounce animation is to move the side swipe view a bit offscreen
            [UIView beginAnimations:nil context:(__bridge void *)([NSNumber numberWithInt:direction])];
            [UIView setAnimationDuration:0.2];
            if (direction == UISwipeGestureRecognizerDirectionLeft) {
                [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                [contentView.layer setPosition:CGPointMake(-BOUNCE_PIXELS/2, contentView.layer.position.y)];
            } else {
                [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                [contentView.layer setPosition:CGPointMake(BOUNCE_PIXELS/2, contentView.layer.position.y)];
            }
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStopOne:finished:context:)];
            [UIView commitAnimations];			
		}
		else
		{
			[self resetViews:NO];
		}
	}
}

#pragma mark Bounce animation when removing the side swipe view
// The next step in a bounce animation is to move the side swipe view a bit on screen
- (void)animationDidStopOne:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    UISwipeGestureRecognizerDirection direction = (UISwipeGestureRecognizerDirection)[(__bridge NSNumber *)context intValue];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    if (direction == UISwipeGestureRecognizerDirectionLeft) {
        [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
        [contentView.layer setPosition:CGPointMake(-BOUNCE_PIXELS, contentView.layer.position.y)];
    }
    else {
        [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
        [contentView.layer setPosition:CGPointMake(BOUNCE_PIXELS, contentView.layer.position.y)];
    }
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopTwo:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView commitAnimations];
}

// The final step in a bounce animation is to move the side swipe completely offscreen
- (void)animationDidStopTwo:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [UIView commitAnimations];
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationDuration:0.2];
    
    [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
    [contentView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
    
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopHidingBackView:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView commitAnimations];
}

- (void)resetViews:(BOOL)animated {
	
	contentViewMoving = NO;
	
	[contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
	[contentView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
	
	[backView.layer setHidden:YES];
	[backView.layer setOpacity:1.0];
	
	[self setSelectionStyle:oldStyle];
	
	[self backViewDidDisappear:animated];
}

// Note that the animation is done
- (void)animationDidStopAddingBackView:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [self backViewDidAppear:YES];
    [self setSelected:NO];
    
    contentViewMoving = NO;
}

- (void)animationDidStopHidingBackView:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [self resetViews:YES];
    
    contentViewMoving = NO;
}

#pragma mark - Other
- (NSString *)description {
	
	NSString * extraInfo = backView.hidden ? @"ContentView visible": @"BackView visible";
	return [NSString stringWithFormat:@"<TISwipeableTableViewCell %p; '%@'>", self, extraInfo];
}
@end

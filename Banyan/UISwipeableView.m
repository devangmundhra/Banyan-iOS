//
//  UISwipeableView.m
//  Banyan
//
//  Created by Devang Mundhra on 3/19/13.
//
//

#import "UISwipeableView.h"
#import <QuartzCore/QuartzCore.h>

@interface UISwipeableView (Private)
- (void)initialSetup;
- (void)resetViews:(BOOL)animated;
@end

@implementation UISwipeableView
@synthesize backView;
@synthesize contentView;
@synthesize contentViewMoving;
@synthesize shouldBounce;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
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

- (void)initialSetup
{
    [self setBackgroundColor:[UIColor whiteColor]];
    
    CGRect newBounds = self.bounds;
    newBounds.size.height -= 1;
    
	contentView = [[UIView alloc] initWithFrame:newBounds];
	[contentView setClipsToBounds:YES];
	[contentView setOpaque:YES];
	[contentView setBackgroundColor:[UIColor clearColor]];
	
    UISwipeGestureRecognizer * frontSwipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(frontViewWasSwiped:)];
	[frontSwipeRecognizerLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
	[contentView addGestureRecognizer:frontSwipeRecognizerLeft];
	
	backView = [[UIView alloc] initWithFrame:newBounds];
	[backView setOpaque:YES];
	[backView setClipsToBounds:YES];
	[backView setHidden:YES];
	[backView setBackgroundColor:[UIColor clearColor]];
    
	UISwipeGestureRecognizer * backSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(backViewWasSwiped:)];
    // The direction of backview swipe depends on how it was revealed
	[backSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
	[backView addGestureRecognizer:backSwipeRecognizer];
	
	[self addSubview:backView];
	[self addSubview:contentView];
	
	contentViewMoving = NO;
	shouldBounce = YES;
}

- (void)prepareForReuse {
	
	[self resetViews:NO];
}

//- (void)setFrame:(CGRect)aFrame {
//	
//	[super setFrame:aFrame];
//	
//	CGRect newBounds = self.bounds;
//	newBounds.size.height -= 1;
//	[backView setFrame:newBounds];
//	[contentView setFrame:newBounds];
//}

- (void)setNeedsDisplay {
	
	[super setNeedsDisplay];
	if (!contentView.hidden) [contentView setNeedsDisplay];
	if (!backView.hidden) [backView setNeedsDisplay];
}

//===============================//

#pragma mark - Back View Show / Hide

- (void)frontViewWasSwiped:(UISwipeGestureRecognizer *)recognizer
{
	[self revealBackViewAnimated:YES inDirection:recognizer.direction];
}

- (void)backViewWasSwiped:(UISwipeGestureRecognizer *)recognizer
{
    [self hideBackViewAnimated:YES inDirection:recognizer.direction];
}

- (void)revealBackViewAnimated:(BOOL)animated inDirection:(UISwipeGestureRecognizerDirection)direction
{
	if (!contentViewMoving && backView.hidden) {
		
		contentViewMoving = YES;
		
		[backView.layer setHidden:NO];
		[backView setNeedsDisplay];
		
        if ([delegate respondsToSelector:@selector(backViewWillAppear:)])
            [delegate backViewWillAppear:animated];
		        
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
            if ([delegate respondsToSelector:@selector(backViewDidAppear:)])
                [delegate backViewDidAppear:animated];
			
			contentViewMoving = NO;
		}
	}
}

#define BOUNCE_PIXELS 20.0

- (void)hideBackViewAnimated:(BOOL)animated inDirection:(UISwipeGestureRecognizerDirection)direction
{
	
	if (!contentViewMoving && !backView.hidden){
		
		contentViewMoving = YES;
		
        if ([delegate respondsToSelector:@selector(backViewWillDisappear:)])
            [delegate backViewWillDisappear:animated];
		
		if (animated) {
            // The first step in a bounce animation is to move the side swipe view a bit offscreen
            [UIView beginAnimations:nil context:(void *)([NSNumber numberWithInt:direction])];
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
    
    if ([delegate respondsToSelector:@selector(backViewDidDisappear:)])
        [delegate backViewDidDisappear:animated];
}

// Note that the animation is done
- (void)animationDidStopAddingBackView:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    if ([delegate respondsToSelector:@selector(backViewDidAppear:)])
        [delegate backViewDidAppear:YES];
    
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
	return [NSString stringWithFormat:@"<UISwipeableView %p; '%@'>", self, extraInfo];
}

@end

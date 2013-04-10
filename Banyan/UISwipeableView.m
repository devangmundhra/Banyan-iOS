//
//  UISwipeableView.m
//  Banyan
//
//  Created by Devang Mundhra on 3/19/13.
//
//

#import "UISwipeableView.h"
#import <QuartzCore/QuartzCore.h>

@implementation UISwipeableViewFrontView
- (void)drawRect:(CGRect)rect {
    
    if ([((UISwipeableView *)self.superview).delegate respondsToSelector:@selector(drawFrontView:)])
        [((UISwipeableView *)self.superview).delegate drawFrontView:rect];
}
@end

@implementation UISwipeableViewBackView
- (void)drawRect:(CGRect)rect {
    if ([((UISwipeableView *)self.superview).delegate respondsToSelector:@selector(drawBackView:)])
        [((UISwipeableView *)self.superview).delegate drawBackView:rect];
}

@end

@interface UISwipeableView (Private)
- (void)initialSetup;
- (void)resetViews:(BOOL)animated;
@end

@implementation UISwipeableView
@synthesize backView;
@synthesize frontView;
@synthesize frontViewMoving;
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
        
	frontView = [[UISwipeableViewFrontView alloc] initWithFrame:newBounds];
	[frontView setClipsToBounds:YES];
	[frontView setOpaque:YES];
	[frontView setBackgroundColor:[UIColor clearColor]];
	
    UISwipeGestureRecognizer * frontSwipeRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(frontViewWasSwiped:)];
	[frontSwipeRecognizerLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
	[frontView addGestureRecognizer:frontSwipeRecognizerLeft];
	
	backView = [[UISwipeableViewBackView alloc] initWithFrame:newBounds];
	[backView setOpaque:YES];
	[backView setClipsToBounds:YES];
	[backView setHidden:YES];
	[backView setBackgroundColor:[UIColor redColor]];
    
	UISwipeGestureRecognizer * backSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(backViewWasSwiped:)];
    // The direction of backview swipe depends on how it was revealed
	[backSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
	[backView addGestureRecognizer:backSwipeRecognizer];
	
	[self addSubview:backView];
	[self addSubview:frontView];
	
	frontViewMoving = NO;
	shouldBounce = YES;
}

- (void)prepareForReuse {
	
	[self resetViews:NO];
}

- (void)setFrame:(CGRect)aFrame
{	
	[super setFrame:aFrame];
	
	CGRect newBounds = self.bounds;
	[backView setFrame:newBounds];
	[frontView setFrame:newBounds];
}

- (void)setNeedsDisplay {
	
	[super setNeedsDisplay];
	if (!frontView.hidden) [frontView setNeedsDisplay];
	if (!backView.hidden) [backView setNeedsDisplay];
}

//===============================//

#pragma mark - Back View Show / Hide

- (void)frontViewWasSwiped:(UISwipeGestureRecognizer *)recognizer
{
    if ([delegate respondsToSelector:@selector(shouldSwipe)])
    {
        if ([delegate shouldSwipe])
            [self revealBackViewAnimated:YES inDirection:recognizer.direction];
    }
    if ([delegate respondsToSelector:@selector(didSwipe)])
        [delegate didSwipe];
}

- (void)backViewWasSwiped:(UISwipeGestureRecognizer *)recognizer
{
    [self hideBackViewAnimated:YES inDirection:recognizer.direction];
}

#define FRONTVIEW_SCALE_FACTOR 0.000000000000001
- (void)revealBackViewAnimated:(BOOL)animated inDirection:(UISwipeGestureRecognizerDirection)direction
{
	if (!frontViewMoving && backView.hidden) {
		
		frontViewMoving = YES;
		[backView.layer setHidden:NO];
		[backView setNeedsDisplay];
		
        if ([delegate respondsToSelector:@selector(backViewWillAppear:)])
            [delegate backViewWillAppear:animated];
		        
		if (animated) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            
            if (direction == UISwipeGestureRecognizerDirectionRight) {
                CGAffineTransform scale = CGAffineTransformMakeScale(FRONTVIEW_SCALE_FACTOR, 1);
                [frontView setTransform:CGAffineTransformTranslate(scale, self.frame.size.width/2/FRONTVIEW_SCALE_FACTOR, 0)];
            } else {
                CGAffineTransform scale = CGAffineTransformMakeScale(FRONTVIEW_SCALE_FACTOR, 1);
                [frontView setTransform:CGAffineTransformTranslate(scale, -self.frame.size.width/2/FRONTVIEW_SCALE_FACTOR, 0)];
            }
            [UIView setAnimationDelegate:self];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            [UIView setAnimationDidStopSelector:@selector(animationDidStopAddingBackView:finished:context:)];
            [UIView commitAnimations];
		}
		else
		{
            if ([delegate respondsToSelector:@selector(backViewDidAppear:)])
                [delegate backViewDidAppear:animated];
			
			frontViewMoving = NO;
		}
	}
}

- (void)hideBackViewAnimated:(BOOL)animated inDirection:(UISwipeGestureRecognizerDirection)direction
{
	
	if (!frontViewMoving && !backView.hidden){
		
		frontViewMoving = YES;
		
        if ([delegate respondsToSelector:@selector(backViewWillDisappear:)])
            [delegate backViewWillDisappear:animated];
		
		if (animated) {
            [UIView beginAnimations:nil context:(void *)([NSNumber numberWithInt:direction])];
            [UIView setAnimationDuration:0.2];
            [frontView setTransform:CGAffineTransformIdentity];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidStopHidingBackView:finished:context:)];
            [UIView commitAnimations];
		}
		else
		{
			[self resetViews:NO];
		}
	}
}

- (void)resetViews:(BOOL)animated {
	
	frontViewMoving = NO;
	
    [frontView setTransform:CGAffineTransformIdentity];
	
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
    
    frontViewMoving = NO;
}

- (void)animationDidStopHidingBackView:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [self resetViews:YES];
    
    frontViewMoving = NO;
}

#pragma mark - Other
- (NSString *)description {
	
	NSString * extraInfo = backView.hidden ? @"FrontView visible": @"BackView visible";
	return [NSString stringWithFormat:@"<UISwipeableView %p; '%@'>", self, extraInfo];
}

@end

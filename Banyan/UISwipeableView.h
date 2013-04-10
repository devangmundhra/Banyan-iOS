//
//  UISwipeableView.h
//  Banyan
//
//  Created by Devang Mundhra on 3/19/13.
//
//

#import <UIKit/UIKit.h>

@interface UISwipeableViewFrontView : UIView
@end

@interface UISwipeableViewBackView : UIView
@end

@protocol UISwipeableViewDelegate <NSObject>

- (BOOL)shouldSwipe;

@optional
- (void)drawFrontView:(CGRect)rect;
- (void)drawBackView:(CGRect)rect;

- (void)backViewWillAppear:(BOOL)animated;
- (void)backViewDidAppear:(BOOL)animated;
- (void)backViewWillDisappear:(BOOL)animated;
- (void)backViewDidDisappear:(BOOL)animated;

- (void)didSwipe;

@end

@interface UISwipeableView : UIView <UIGestureRecognizerDelegate> {
	
	UIView * frontView;
	UIView * backView;
	
	BOOL contentViewMoving;
	BOOL shouldBounce;
}

@property (nonatomic, strong) UIView * backView;
@property (nonatomic, strong) UIView * frontView;
@property (nonatomic, assign) BOOL frontViewMoving;
@property (nonatomic, assign) BOOL shouldBounce;
@property (nonatomic, strong) id<UISwipeableViewDelegate> delegate;

- (void)revealBackViewAnimated:(BOOL)animated inDirection:(UISwipeGestureRecognizerDirection)direction;
- (void)hideBackViewAnimated:(BOOL)animated inDirection:(UISwipeGestureRecognizerDirection)direction;

- (void)prepareForReuse;

@end

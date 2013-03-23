//
//  UISwipeableView.h
//  Banyan
//
//  Created by Devang Mundhra on 3/19/13.
//
//

#import <UIKit/UIKit.h>

@protocol UISwipeableViewDelegate <NSObject>

@optional
- (void)drawContentView:(CGRect)rect;
- (void)drawBackView:(CGRect)rect;

- (void)backViewWillAppear:(BOOL)animated;
- (void)backViewDidAppear:(BOOL)animated;
- (void)backViewWillDisappear:(BOOL)animated;
- (void)backViewDidDisappear:(BOOL)animated;

@end

@interface UISwipeableView : UIView <UIGestureRecognizerDelegate> {
	
	UIView * contentView;
	UIView * backView;
	
	BOOL contentViewMoving;
	BOOL shouldBounce;
}

@property (nonatomic, strong) UIView * backView;
@property (nonatomic, strong) UIView * contentView;
@property (nonatomic, assign) BOOL contentViewMoving;
@property (nonatomic, assign) BOOL shouldBounce;
@property (nonatomic, strong) id<UISwipeableViewDelegate> delegate;

- (void)revealBackViewAnimated:(BOOL)animated inDirection:(UISwipeGestureRecognizerDirection)direction;
- (void)hideBackViewAnimated:(BOOL)animated inDirection:(UISwipeGestureRecognizerDirection)direction;

- (void)prepareForReuse;

@end

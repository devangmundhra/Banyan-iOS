//
//  BNZoomAnimationController.h
//  Banyan
//
//  Created by Devang Mundhra on 12/11/13.
//
//

#import "BNZoomAnimationController.h"

static CGFloat const MEZoomAnimationScaleFactor = 0.75;

@interface BNZoomAnimationController ()
@property (nonatomic, assign) ECSlidingViewControllerOperation operation;
- (CGRect)topViewAnchoredRightFrame:(ECSlidingViewController *)slidingViewController;
- (void)topViewStartingState:(UIView *)topView containerFrame:(CGRect)containerFrame;
- (void)topViewAnchorRightEndState:(UIView *)topView anchoredFrame:(CGRect)anchoredFrame;
- (void)underLeftViewStartingState:(UIView *)underLeftView containerFrame:(CGRect)containerFrame;
- (void)underLeftViewEndState:(UIView *)underLeftView;
@end

@implementation BNZoomAnimationController

#pragma mark - ECSlidingViewControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)slidingViewController:(ECSlidingViewController *)slidingViewController
                                   animationControllerForOperation:(ECSlidingViewControllerOperation)operation
                                                 topViewController:(UIViewController *)topViewController {
    self.operation = operation;
    return self;
}

- (id<ECSlidingViewControllerLayout>)slidingViewController:(ECSlidingViewController *)slidingViewController
                        layoutControllerForTopViewPosition:(ECSlidingViewControllerTopViewPosition)topViewPosition {
    return self;
}

#pragma mark - ECSlidingViewControllerLayout

- (CGRect)slidingViewController:(ECSlidingViewController *)slidingViewController
         frameForViewController:(UIViewController *)viewController
                topViewPosition:(ECSlidingViewControllerTopViewPosition)topViewPosition {
    if (topViewPosition == ECSlidingViewControllerTopViewPositionAnchoredRight && viewController == slidingViewController.topViewController) {
        return [self topViewAnchoredRightFrame:slidingViewController];
    } else {
        return CGRectInfinite;
    }
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *topViewController = [transitionContext viewControllerForKey:ECTransitionContextTopViewControllerKey];
    UIViewController *underLeftViewController  = [transitionContext viewControllerForKey:ECTransitionContextUnderLeftControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    UIView *topView = topViewController.view;
    topView.frame = containerView.bounds;
    
    underLeftViewController.view.layer.transform = CATransform3DIdentity;
    
    if (self.operation == ECSlidingViewControllerOperationAnchorRight) {
        [containerView insertSubview:underLeftViewController.view belowSubview:topView];
        
        [self topViewStartingState:topView containerFrame:containerView.bounds];
        [self underLeftViewStartingState:underLeftViewController.view containerFrame:containerView.bounds];

        NSTimeInterval duration = [self transitionDuration:transitionContext];
        [UIView animateWithDuration:duration animations:^{
            [self underLeftViewEndState:underLeftViewController.view];
            [self topViewAnchorRightEndState:topView anchoredFrame:[transitionContext finalFrameForViewController:topViewController]];
        } completion:^(BOOL finished) {
            if ([transitionContext transitionWasCancelled]) {
                underLeftViewController.view.frame = [transitionContext finalFrameForViewController:underLeftViewController];
                underLeftViewController.view.alpha = 1;
                [self topViewStartingState:topView containerFrame:containerView.bounds];
            }
            
            [transitionContext completeTransition:finished];
        }];
    } else if (self.operation == ECSlidingViewControllerOperationResetFromRight) {
        [self topViewAnchorRightEndState:topView anchoredFrame:[transitionContext initialFrameForViewController:topViewController]];
        [self underLeftViewEndState:underLeftViewController.view];

        NSTimeInterval duration = [self transitionDuration:transitionContext];
        [UIView animateWithDuration:duration animations:^{
            [self underLeftViewStartingState:underLeftViewController.view containerFrame:containerView.bounds];
            [self topViewStartingState:topView containerFrame:containerView.bounds];
        } completion:^(BOOL finished) {
            if ([transitionContext transitionWasCancelled]) {
                [self underLeftViewEndState:underLeftViewController.view];
                [self topViewAnchorRightEndState:topView anchoredFrame:[transitionContext initialFrameForViewController:topViewController]];
            } else {
                underLeftViewController.view.alpha = 1;
                underLeftViewController.view.layer.transform = CATransform3DIdentity;
                [underLeftViewController.view removeFromSuperview];
            }
            
            [transitionContext completeTransition:finished];
        }];
    }
}

#pragma mark - Private

- (CGRect)topViewAnchoredRightFrame:(ECSlidingViewController *)slidingViewController {
    CGRect frame = slidingViewController.view.bounds;
    
    frame.origin.x    = slidingViewController.anchorRightRevealAmount;
    frame.size.width  = frame.size.width  * MEZoomAnimationScaleFactor;
    frame.size.height = frame.size.height * MEZoomAnimationScaleFactor;
    frame.origin.y    = (slidingViewController.view.bounds.size.height - frame.size.height) / 2;
    
    return frame;
}

- (void)topViewStartingState:(UIView *)topView containerFrame:(CGRect)containerFrame {
    topView.layer.transform = CATransform3DIdentity;
    topView.layer.position  = CGPointMake(containerFrame.size.width / 2, containerFrame.size.height / 2);
}

- (void)topViewAnchorRightEndState:(UIView *)topView anchoredFrame:(CGRect)anchoredFrame {
    topView.layer.transform = CATransform3DMakeScale(MEZoomAnimationScaleFactor, MEZoomAnimationScaleFactor, 1);
    topView.frame = anchoredFrame;
    topView.layer.position  = CGPointMake(anchoredFrame.origin.x + ((topView.layer.bounds.size.width * MEZoomAnimationScaleFactor) / 2), topView.layer.position.y);
}

- (void)underLeftViewStartingState:(UIView *)underLeftView containerFrame:(CGRect)containerFrame {
    underLeftView.alpha = 0;
    underLeftView.frame = containerFrame;
    underLeftView.layer.transform = CATransform3DMakeScale(1.25, 1.25, 1);
}

- (void)underLeftViewEndState:(UIView *)underLeftView {
    underLeftView.alpha = 1;
    underLeftView.layer.transform = CATransform3DIdentity;
}

@end

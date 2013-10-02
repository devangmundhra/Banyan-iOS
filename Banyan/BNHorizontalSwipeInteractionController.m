//
//  BNHorizontalSwipeInteractionController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/29/13.
//
//

#import "BNHorizontalSwipeInteractionController.h"

@implementation BNHorizontalSwipeInteractionController {
    BOOL _shouldCompleteTransition;
    UIViewController *_viewController;
    UIPanGestureRecognizer *_gesture;
    CEInteractionOperation _operation;
}

-(void)dealloc {
    [_gesture.view removeGestureRecognizer:_gesture];
}

- (void)wireToViewController:(UIViewController *)viewController forOperation:(CEInteractionOperation)operation{
    _operation = operation;
    _viewController = viewController;
    [self prepareGestureRecognizerInView:viewController.view];
    SEL selector = NSSelectorFromString(@"interactionControllerDidWireToViewWithGestureRecognizer:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([viewController respondsToSelector:selector]) {
        [viewController performSelector:selector withObject:_gesture];
    }
#pragma clang diagnostic pop
}


- (void)prepareGestureRecognizerInView:(UIView*)view {
    _gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    [view addGestureRecognizer:_gesture];
}

- (CGFloat)completionSpeed
{
    return 1 - self.percentComplete;
}

- (void)handleGesture:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view.superview];
    CGPoint vel = [gestureRecognizer velocityInView:gestureRecognizer.view];
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            
            BOOL rightToLeftSwipe = vel.x < 0;
            
            // perform the required navigation operation ...
            
            if (_operation == CEInteractionOperationPop) {
                // for pop operation, fire on right-to-left
                if (rightToLeftSwipe) {
                    self.interactionInProgress = YES;
                    [_viewController.navigationController popViewControllerAnimated:YES];
                }
            } else if (_operation == CEInteractionOperationTab) {
                // for tab controllers, we need to determine which direction to transition
                if (rightToLeftSwipe) {
                    if (_viewController.tabBarController.selectedIndex < _viewController.tabBarController.viewControllers.count - 1) {
                        self.interactionInProgress = YES;
                        _viewController.tabBarController.selectedIndex++;
                    }
                    
                } else {
                    if (_viewController.tabBarController.selectedIndex > 0) {
                        self.interactionInProgress = YES;
                        _viewController.tabBarController.selectedIndex--;
                    }
                }
            } else {
                // for dismiss, fire only on left-to-right
                if (!rightToLeftSwipe) {
                    self.interactionInProgress = YES;
                    [_viewController dismissViewControllerAnimated:YES completion:nil];
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (self.interactionInProgress) {
                // compute the current position
                CGFloat fraction = fabsf(translation.x / 200.0);
                fraction = fminf(fmaxf(fraction, 0.0), 1.0);
                _shouldCompleteTransition = (fraction > 0.5);
                
                // if an interactive transitions is 100% completed via the user interaction, for some reason
                // the animation completion block is not called, and hence the transition is not completed.
                // This glorious hack makes sure that this doesn't happen.
                // see: https://github.com/ColinEberhardt/VCTransitionsLibrary/issues/4
                if (fraction >= 1.0)
                    fraction = 0.99;
                
                [self updateInteractiveTransition:fraction];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            if (self.interactionInProgress) {
                self.interactionInProgress = NO;
                if (!_shouldCompleteTransition || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
                    [self cancelInteractiveTransition];
                }
                else {
                    [self finishInteractiveTransition];
                }
            }
            break;
        default:
            break;
    }
}


@end

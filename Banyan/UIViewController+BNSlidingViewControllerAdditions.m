//
//  UIViewController+BNSlidingViewControllerAdditions.m
//  Banyan
//
//  Created by Devang Mundhra on 12/11/13.
//
//

#import "UIViewController+BNSlidingViewControllerAdditions.h"
#import "BNZoomAnimationController.h"

@implementation UIViewController (BNSlidingViewControllerAdditions)

+ (BNZoomAnimationController *)zoomAnimationController {
    static BNZoomAnimationController *zoomAnimationController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zoomAnimationController = [[BNZoomAnimationController alloc] init];
    });
    return zoomAnimationController;
}
- (void) prepareForSlidingViewController
{
    self.navigationItem.leftBarButtonItem = [self leftButtonForTopViewController];
    self.slidingViewController.delegate = [[self class] zoomAnimationController];
    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
}

- (UIBarButtonItem *)leftButtonForTopViewController
{
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:[[self class] defaultImage] style:UIBarButtonItemStylePlain target:self action:@selector(anchorRight:)];
    button.tintColor = BANYAN_GREEN_COLOR;
    return button;
}

#pragma mark - Icon

+ (UIImage *)defaultImage {
    static UIImage *defaultImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(20.f, 13.f), NO, 0.0f);
        
        [[UIColor blackColor] setFill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 20, 1)] fill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(0, 5, 20, 1)] fill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(0, 10, 20, 1)] fill];
        
        [[UIColor whiteColor] setFill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(0, 1, 20, 2)] fill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(0, 6,  20, 2)] fill];
        [[UIBezierPath bezierPathWithRect:CGRectMake(0, 11, 20, 2)] fill];
        
        defaultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
    });
    return defaultImage;
}

#pragma mark target-actions
- (IBAction)anchorRight:(id)sender
{
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

@end

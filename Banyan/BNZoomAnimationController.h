//
//  BNZoomAnimationController.h
//  Banyan
//
//  Created by Devang Mundhra on 12/11/13.
//
//
#import <Foundation/Foundation.h>
#import "ECSlidingViewController.h"

@interface BNZoomAnimationController : NSObject <UIViewControllerAnimatedTransitioning,
                                                 ECSlidingViewControllerDelegate,
                                                 ECSlidingViewControllerLayout>
@end

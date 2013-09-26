//
//  BNTabBarController.h
//  Banyan
//
//  Created by Devang Mundhra on 3/16/13.
//
//

#import <UIKit/UIKit.h>

@interface BNTabBarController : UITabBarController

- (void) addCenterButtonWithImage:(UIImage *)image andTarget:(id)target withAction:(SEL)action;
- (void) hideCenterButton;
- (void) showCenterButton;

@end

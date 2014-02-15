//
//  BNNavigationController.h
//  Banyan
//
//  Created by Devang Mundhra on 2/14/14.
//
//

#import <UIKit/UIKit.h>

@interface BNNavigationController : UINavigationController <UINavigationControllerDelegate>

- (UIViewController *) popViewControllerAnimated:(BOOL) animated completion:(void (^)()) completion;

@end

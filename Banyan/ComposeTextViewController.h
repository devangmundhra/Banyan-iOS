//
//  ComposeTextViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 11/18/12.
//
//

#import <Foundation/Foundation.h>

@class ComposeTextViewController;

@protocol ComposeTextViewControllerDelegate <NSObject>

- (void) doneWithComposeTextViewController:(ComposeTextViewController *)controller;

- (void) cancelComposeTextViewController:(ComposeTextViewController *)controller;

@end

@interface ComposeTextViewController : UIViewController <UITextViewDelegate>

@property (weak, nonatomic) id <ComposeTextViewControllerDelegate> delegate;
@property (strong, nonatomic) UITextView *textView;

@end

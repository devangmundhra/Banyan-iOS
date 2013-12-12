//
//  BNFeedbackViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 6/10/13.
//
//

#import "BNFeedbackViewController.h"
#import "UIPlaceHolderTextView.h"
#import "UIViewController+BNSlidingViewControllerAdditions.h"

@interface BNFeedbackViewController ()

@property (strong, nonatomic) UIPlaceHolderTextView *textView;

@end

@implementation BNFeedbackViewController
@synthesize textView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Feedback";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    CGRect frame = self.view.bounds;
    frame.size.height -= CGRectGetHeight(self.navigationController.navigationBar.frame);
    textView = [[UIPlaceHolderTextView alloc] initWithFrame:frame];
    textView.font = [UIFont fontWithName:@"Roboto" size:18];
    textView.textAlignment = NSTextAlignmentLeft;
    textView.placeholder = @"Please tell us what you think about Banyan. What you like, what you don't like, or just a hi.\nWe would love to hear from you!";
    textView.scrollEnabled = YES;    
    [self.view addSubview:textView];
    [self registerForKeyboardNotifications];
    
    [self prepareForSlidingViewController];
    [textView becomeFirstResponder];

}

- (void)dealloc
{
    [self unregisterForKeyboardNotifications];
}

# pragma mark - Keyboard notifications
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    textView.contentInset = contentInsets;
    textView.scrollIndicatorInsets = contentInsets;    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillHide:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    textView.contentInset = contentInsets;
    textView.scrollIndicatorInsets = contentInsets;
    
    [textView setContentOffset:CGPointZero animated:YES];
}

#pragma mark target actions
- (IBAction)doneButtonPressed:(id)sender
{
    [TestFlight submitFeedback:textView.text];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    textView.text = @"Thank you for your feedback!";
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

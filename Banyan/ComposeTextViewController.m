//
//  ComposeTextViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 11/18/12.
//
//

#import "ComposeTextViewController.h"

@interface ComposeTextViewController ()
@property (strong, nonatomic) UILabel *charCountLabel;

@end

@implementation ComposeTextViewController

@synthesize delegate = _delegate;
@synthesize textView = _textView;
@synthesize charCountLabel = _charCountLabel;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [self.view addSubview:navBar];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancel)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(done)];
    
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Edit Text"];
    navItem.leftBarButtonItem = cancelButton;
    navItem.rightBarButtonItem = doneButton;
    
    navBar.items = [NSArray arrayWithObjects:navItem, nil];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    CGRect viewFrame = screenRect;
    viewFrame.origin = CGPointMake(0, navBar.frame.origin.y + navBar.frame.size.height);
    viewFrame.size = CGSizeMake(viewFrame.size.width, viewFrame.size.height-navBar.frame.size.height);
    self.textView = [[UITextView alloc] initWithFrame:viewFrame];
//    self.textView.contentInset = UIEdgeInsetsMake(8,8,8,8);
    self.textView.textAlignment = UITextAlignmentLeft;
    self.textView.returnKeyType = UIReturnKeyDefault;
    self.textView.scrollEnabled = YES;
    self.textView.delegate = self;
    
    self.textView.font = [UIFont systemFontOfSize:18];
    
    [self.view addSubview:self.textView];
    
    [self registerForKeyboardNotifications];
    
    self.charCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenRect.size.width - 50,
                                                                    screenRect.size.height - 20,
                                                                    50, 20)];
    self.charCountLabel.backgroundColor = [UIColor clearColor];
    self.charCountLabel.font = [UIFont systemFontOfSize:12];
    self.charCountLabel.textColor = [UIColor lightGrayColor];
    self.charCountLabel.text = [NSString stringWithFormat:@"%u chars", [self.textView.text length]];
    self.charCountLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.charCountLabel];
    
    [self.textView becomeFirstResponder];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self unregisterForKeyboardNotifications];
    
    self.delegate = nil;
    self.textView = nil;
    self.charCountLabel = nil;
    [self.textView resignFirstResponder];
}

#pragma mark Target-Actions

- (void) done
{
    [self.delegate doneWithComposeTextViewController:self];
}

- (void) cancel
{
    [self.delegate cancelComposeTextViewController:self];
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
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];

    self.charCountLabel.frame = CGRectMake(screenRect.size.width - 120,
                                           screenRect.size.height - keyboardSize.height - statusRect.size.height - 20,
                                           100, 20);
    CGRect viewFrame = self.textView.frame;
    viewFrame.size = CGSizeMake(viewFrame.size.width, viewFrame.size.height-keyboardSize.height-statusRect.size.height);
    self.textView.frame = viewFrame;
    
    [UIView commitAnimations];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillHide:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];
    
    self.charCountLabel.frame = CGRectMake(screenRect.size.width - 120,
                                           screenRect.size.height - 20,
                                           100, 20);
    
    CGRect viewFrame = self.textView.frame;
    viewFrame.size = CGSizeMake(viewFrame.size.width, viewFrame.size.height+keyboardSize.height+statusRect.size.height);
    
    self.textView.frame = viewFrame;
    
    [UIView commitAnimations];
}

#pragma UITextView delegate
- (void)textViewDidChange:(UITextView *)textView
{
    self.charCountLabel.text = [NSString stringWithFormat:@"%u chars", [textView.text length]];
}

@end

//
//  ModifyPieceMetadataViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 7/12/13.
//
//

#import "ModifyPieceMetadataViewController.h"

@interface ModifyPieceMetadataViewController ()

@property (strong, nonatomic) UIBarButtonItem *doneButton;

@property (weak, nonatomic) IBOutlet LocationPickerButton *addLocationButton;
@property (strong, nonatomic) BNFBLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet TITokenFieldView *tagsFieldView;

@property (weak, nonatomic) UITextField *activeField;
@property (nonatomic) CGSize kbSize;

@property (strong, nonatomic) UIScrollView *scrollView;

@end

@implementation ModifyPieceMetadataViewController

@synthesize locationManager = _locationManager;
@synthesize addLocationButton;
@synthesize activeField = _activeField;
@synthesize delegate = _delegate;
@synthesize scrollView = _scrollView;
@synthesize doneButton = _doneButton;

#define kTokenisingCharacter @","

- (Piece *)piece
{
    return [self.delegate piece];
}

- (id) initWithDelegate:(id<ModifyPieceMetadataViewControllerDelegate>)delegate
{
    if (self = [super initWithNibName:@"ModifyPieceMetadataViewController" bundle:nil]) {
        self.delegate = delegate;
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        assert(false);
    }
    return self;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
//    if (self.editMode == ModifyPieceViewControllerEditModeAddPiece && self.piece.story.isLocationEnabled)
        [self.locationManager stopUpdatingLocation:self.piece.location.name];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // If story has location enabled, only then try to get the location
    if (self.piece.story.isLocationEnabled) {
        self.locationManager = [[BNFBLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager beginUpdatingLocation];
        self.locationManager.location = self.piece.location;
    } else {
        [self.addLocationButton setEnabled:NO];
    }
    
    if ([self.piece.location.name length]) {
        [self.addLocationButton locationPickerLocationEnabled:YES];
        [self.addLocationButton setLocationPickerTitle:self.piece.location.name];
    }
    self.addLocationButton.delegate = self;
    
    // Tags
    self.tagsFieldView.scrollEnabled = NO;
    [self.tagsFieldView.tokenField setDelegate:self];
	[self.tagsFieldView.tokenField addTarget:self action:@selector(tokenFieldFrameDidChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
	[self.tagsFieldView.tokenField setTokenizingCharacters:[NSCharacterSet characterSetWithCharactersInString:@",;."]]; // Default is a comma
    [self.tagsFieldView.tokenField addTarget:self action:@selector(tokenFieldChangedEditing:) forControlEvents:UIControlEventEditingDidBegin];
	[self.tagsFieldView.tokenField addTarget:self action:@selector(tokenFieldChangedEditing:) forControlEvents:UIControlEventEditingDidEnd];
    self.tagsFieldView.tokenField.returnKeyType = UIReturnKeyDone;
    if (self.piece.tags) {
        [[self.piece.tags componentsSeparatedByString:kTokenisingCharacter]
         enumerateObjectsUsingBlock:^(NSString *token, NSUInteger idx, BOOL *stop) {
             [self.tagsFieldView.tokenField addTokenWithTitle:token];
         }];
    }
    else {
        [self.tagsFieldView.tokenField setPromptText:@"Tags: "];
    }
    
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark LocationPickerButtonDelegate
- (void)locationPickerButtonTapped:(LocationPickerButton *)sender
{
    [self.addLocationButton locationPickerLocationEnabled:YES];
    [self.locationManager showPlacePickerViewController];
}

- (void)locationPickerButtonToggleLocationEnable:(LocationPickerButton *)sender
{
    BOOL isLocationEnabled = sender.getEnabledState;
    isLocationEnabled = !isLocationEnabled;
    [self.addLocationButton locationPickerLocationEnabled:isLocationEnabled];
    if (isLocationEnabled) {
        [self locationPickerButtonTapped:sender];
    } else {
        [self.locationManager stopUpdatingLocation:nil];
    }
}

# pragma mark BNLocationManagerDelegate
- (void) locationUpdated
{
    [self.addLocationButton locationPickerLocationUpdatedWithLocation:self.locationManager.location];
    [self.addLocationButton locationPickerLocationEnabled:YES];
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
    self.kbSize = kbSize;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    if (self.activeField == self.tagsFieldView.tokenField) {
        CGRect aRect = self.view.frame;
        aRect.size.height -= self.kbSize.height;
        
        CGRect translatedFrame = [self.scrollView convertRect:self.tagsFieldView.separator.frame fromView:self.tagsFieldView];
        
        if (!CGRectContainsPoint(aRect, translatedFrame.origin)) {
            CGPoint scrollPoint = CGPointMake(0.0, CGRectGetMaxY(translatedFrame) - self.kbSize.height + 10);
            [self.scrollView setContentOffset:scrollPoint animated:YES];
        }
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillHide:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}


- (IBAction)dismissKeyboard:(id)sender
{    
    if (self.activeField.isFirstResponder)
        [self.activeField resignFirstResponder];
}

#pragma mark TITokenField Delegate
- (BOOL)tokenField:(TITokenField *)tokenField willRemoveToken:(TIToken *)token
{
	return YES;
}

- (void)tokenFieldChangedEditing:(TITokenField *)tokenField
{
	// There's some kind of annoying bug where UITextFieldViewModeWhile/UnlessEditing doesn't do anything.
	[tokenField setRightViewMode:(tokenField.editing ? UITextFieldViewModeAlways : UITextFieldViewModeNever)];
}

- (void)tokenFieldFrameDidChange:(TITokenField *)tokenField
{
    if (self.activeField == self.tagsFieldView.tokenField) {
        if (self.activeField == self.tagsFieldView.tokenField) {
            CGRect aRect = self.view.frame;
            aRect.size.height -= self.kbSize.height;
            
            CGRect translatedFrame = [self.scrollView convertRect:self.tagsFieldView.separator.frame fromView:self.tagsFieldView];
            
            if (!CGRectContainsPoint(aRect, translatedFrame.origin)) {
                CGPoint scrollPoint = CGPointMake(0.0, CGRectGetMaxY(translatedFrame) - self.kbSize.height + 10);
                [self.scrollView setContentOffset:scrollPoint animated:YES];
            }
        }
    }
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
}

// Done modifying piece. Now save all the changes.
- (IBAction)done:(UIBarButtonItem *)sender
{
    if (self.piece.story.isLocationEnabled == YES ) {
        self.piece.location = (FBGraphObject<FBGraphPlace> *)self.locationManager.location;
    }
    
    [self.delegate done];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

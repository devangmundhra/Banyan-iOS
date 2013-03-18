//
//  ModifySceneViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModifySceneViewController.h"
#import "Piece+Create.h"
#import "Piece+Edit.h"
#import "Piece+Delete.h"
#import "Story+Delete.h"
#import "Story+Edit.h"
#import "Piece_Defines.h"
#import "Story_Defines.h"
#import "UIImageView+AFNetworking.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MBProgressHUD.h"
#import "UIImage+ResizeAdditions.h"

@interface ModifySceneViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *sceneCaptionView;
@property (weak, nonatomic) IBOutlet UITextView *pieceTextView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *addLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;

@property (strong, nonatomic) NSString *localImageURL;
@property (nonatomic) BOOL imageChanged;

@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

@property (nonatomic) BOOL keyboardIsShown;
@property (nonatomic) NSUInteger contentViewDispositionOnKeyboard;

@property (strong, nonatomic) BNLocationManager *locationManager;

@end

@implementation ModifySceneViewController

#define MEM_WARNING_USER_DEFAULTS_TEXT_FIELD @"ModifySceneViewControllerText"

@synthesize pieceTextView = _pieceTextView;
@synthesize navigationBar = _navigationBar;
@synthesize cancelButton = _cancelButton;
@synthesize doneButton = _doneButton;
@synthesize piece = _scene;
@synthesize delegate = _delegate;
@synthesize keyboardIsShown = _keyboardIsShown;
@synthesize editMode = _editMode;
@synthesize tapRecognizer = _tapRecognizer;
@synthesize imageChanged = _imageChanged;
@synthesize contentViewDispositionOnKeyboard = _contentViewDispositionOnKeyboard;
@synthesize localImageURL = _localImageURL;
@synthesize locationManager = _locationManager;
@synthesize sceneCaptionView, addLocationButton, addPhotoButton;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.pieceTextView.delegate = self;

    self.pieceTextView.backgroundColor = [UIColor clearColor];
    
    self.pieceTextView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.pieceTextView.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    self.pieceTextView.layer.shadowOpacity = 1.0;
    self.pieceTextView.layer.shadowRadius = 0.3;
    
    self.navigationBar.delegate = self;
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.editMode == add && self.piece.story.isLocationEnabled) {
        self.locationManager = [[BNLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager beginUpdatingLocation];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.editMode == add && self.piece.story.isLocationEnabled) {
        [self.locationManager stopUpdatingLocation:self.addLocationButton.titleLabel.text];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.piece.geocodedLocation && ![self.piece.geocodedLocation isEqual:[NSNull null]]) {
        self.addLocationButton.titleLabel.text = self.piece.geocodedLocation;
    }
    
    if (self.editMode == add)
    {
        self.navigationBar.topItem.title = @"Add Scene";
    }
    else if (self.editMode == edit)
    {
        self.localImageURL = self.piece.imageURL;
        if (self.piece.imageURL && [self.piece.imageURL rangeOfString:@"asset"].location == NSNotFound) {
            [self.addPhotoButton.imageView setImageWithURL:[NSURL URLWithString:self.piece.imageURL] placeholderImage:nil];
        } else if (self.piece.imageURL) {
            ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
            [library assetForURL:[NSURL URLWithString:self.piece.imageURL] resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                CGImageRef imageRef = [rep fullScreenImage];
                UIImage *image = [UIImage imageWithCGImage:imageRef];
                [self.addPhotoButton.imageView setImage:image];
            }
                    failureBlock:^(NSError *error) {
                        NSLog(@"***** ERROR IN FILE CREATE ***\nCan't find the asset library image");
                    }
             ];
        } else {
            [self.addPhotoButton.imageView  cancelImageRequestOperation];
            [self.addPhotoButton.imageView  setImageWithURL:nil];
        }
        self.pieceTextView.text = self.piece.text;
        self.navigationBar.topItem.title = @"Edit";
    }
    
    // if there is a saved mem object due to a memory warning, get that field
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *previousSceneText = [defaults objectForKey:MEM_WARNING_USER_DEFAULTS_TEXT_FIELD];
    if (previousSceneText) {
        self.pieceTextView.text = previousSceneText;
    }
    [defaults removeObjectForKey:MEM_WARNING_USER_DEFAULTS_TEXT_FIELD];
    
    
    self.doneButton.enabled = NO;
    
    self.imageChanged = NO;
    
    [self registerForKeyboardNotifications];
    
//    self.navigationBar.translucent = YES;
}

- (void)viewDidUnload
{
    [self setNavigationBar:nil];
    [self setPieceTextView:nil];
    [self setCancelButton:nil];
    [self setDoneButton:nil];
    [self setLocalImageURL:nil];
    self.locationManager.delegate = nil;
    [self setLocationManager:nil];
    [self setSceneCaptionView:nil];
    [self setAddLocationButton:nil];
    [self setAddPhotoButton:nil];
    [self setScrollView:nil];
    [super viewDidUnload]; 
    [self unregisterForKeyboardNotifications];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark target actions from navigation bar

- (IBAction)cancel:(UIBarButtonItem *)sender 
{
    [self.delegate modifySceneViewControllerDidCancel:self];
}

// Done modifying scene. Now save all the changes.
- (IBAction)done:(UIBarButtonItem *)sender 
{
    self.piece.text = self.pieceTextView.text;
    self.piece.imageURL = self.localImageURL;
    
    if (self.editMode == add)
    {
        if ([self.piece.story.isLocationEnabled boolValue] == YES) {
            if (self.locationManager.location) {
                
                CLLocationCoordinate2D coord = [self.locationManager.location coordinate];
                
                self.piece.latitude = [NSNumber numberWithDouble:coord.latitude];
                self.piece.longitude = [NSNumber numberWithDouble:coord.longitude];
                self.piece.geocodedLocation = self.locationManager.location.name;
            }
        }
        
        [Piece createNewPiece:self.piece afterPiece:nil];
        NSLog(@"New scene %@ saved", self.piece);
        [self.delegate modifySceneViewController:self didFinishAddingScene:self.piece];
        [TestFlight passCheckpoint:@"New scene created successfully"];
    }
    else if (self.editMode == edit)
    {
        self.piece.text = self.pieceTextView.text;
        if (self.imageChanged) {
            self.piece.imageURL = self.localImageURL;
            self.piece.imageChanged = [NSNumber numberWithBool:YES];
            //            self.scene.image = self.imageView.image;
        }
        [Piece editPiece:self.piece];
        [self.delegate modifySceneViewController:self didFinishEditingScene:self.piece];
    }
    else {
        assert(false);
        NSLog(@"ModifySceneViewController_No valid edit mode");
    }
}

- (IBAction)deleteSceneAlert:(UIBarButtonItem *)sender
{
    UIAlertView *alertView = nil;
    alertView = [[UIAlertView alloc] initWithTitle:@"Delete Scene"
                                           message:@"Do you want to delete this scene?"
                                          delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    
    [alertView show];
}

- (void)deletePiece:(UIBarButtonItem *)sender
{
    NSLog(@"ModifySceneViewController_Deleting scene");
    [Piece deletePiece:self.piece];
    [self.delegate modifySceneViewControllerDeletedScene:self];
    [TestFlight passCheckpoint:@"Scene deleted"];
}

- (IBAction)modifyText:(id)sender
{
    // Create a text view scene controller
    ComposeTextViewController *textController = [[ComposeTextViewController alloc] init];
    textController.delegate = self;
    
    [self presentViewController:textController animated:YES completion:^{
        textController.textView.text = self.pieceTextView.text;
    }];
}

#define CAMERA @"Camera"
#define PHOTO_LIB @"Photo Library"
- (IBAction)modifyImage:(id)sender
{
    [self dismissKeyboard:sender];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Modify Photo"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:self.localImageURL ? @"Delete Photo" : nil
                                                    otherButtonTitles:nil];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        [actionSheet addButtonWithTitle:CAMERA];
    [actionSheet addButtonWithTitle:PHOTO_LIB];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==1) {
        [self deletePiece:nil];
    }
}
#pragma mark UIActionSheetDelegate
// Action sheet delegate method.
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        // DO NOTHING ON CANCEL
    }
    else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // MAYBE EXPLICITLY DELETE IMAGE IN FUTURE
        [self.addPhotoButton.imageView cancelImageRequestOperation];
        [self.addPhotoButton.imageView setImageWithURL:nil];
        self.localImageURL = nil;
        self.imageChanged = YES;
        self.doneButton.enabled = [self checkForChanges];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:CAMERA]) {
        [self shouldStartCameraController];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:PHOTO_LIB]) {
        [self shouldStartPhotoLibraryPickerController];
    }
    else {
        NSLog(@"ModifySceneViewController_actionSheetclickedButtonAtIndex %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
    }
}

- (BOOL)shouldStartCameraController {
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && [[UIImagePickerController availableMediaTypesForSourceType:
             UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        } else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        
    } else {
        return NO;
    }
    
//    cameraUI.allowsEditing = YES;
    cameraUI.showsCameraControls = YES;
    cameraUI.delegate = self;

    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return YES;
}

- (BOOL)shouldStartPhotoLibraryPickerController {
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO
         && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]
        && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]
               && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        
    } else {
        return NO;
    }
    
//    cameraUI.allowsEditing = YES;
    cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return YES;
}

# pragma mark - Image Picker
- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        // If the image view controller is completed successfully, we don't really need to keep this saved
        // as a presented screen will not be affected by mem warning.
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MEM_WARNING_USER_DEFAULTS_TEXT_FIELD];
    }];
    
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    self.localImageURL = [(NSURL *)[info objectForKey:@"UIImagePickerControllerReferenceURL"] absoluteString];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if( [picker sourceType] == UIImagePickerControllerSourceTypeCamera )
    {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Saving Picture";
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
        
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error )
         {
             if (assetURL) {
                 NSLog(@"%s Image saved to photo albums %@", __PRETTY_FUNCTION__, assetURL);
                 self.localImageURL = [assetURL absoluteString];
             } else {
                 NSLog(@"%s Error saving image: %@",error);
             }
             [MBProgressHUD hideHUDForView:self.view animated:YES];
         }];
    }

    [self.addPhotoButton.imageView  cancelImageRequestOperation];
    self.pieceTextView.textColor = [UIColor whiteColor];
    self.imageChanged = YES;
    [NSThread detachNewThreadSelector:@selector(useImage:) toTarget:self withObject:image];
    self.doneButton.enabled = [self checkForChanges];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker 
{
    self.localImageURL = nil;
    self.imageChanged = NO;
    [self dismissViewControllerAnimated:YES completion:^{
        // If the image view controller is completed successfully, we don't really need to keep this saved
        // as a presented screen will not be affected by mem warning.
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MEM_WARNING_USER_DEFAULTS_TEXT_FIELD];
    }];
}

- (void)useImage:(UIImage *)image {    
    // Create a graphics image context
    CGRect screenSize = [[UIScreen mainScreen] bounds];

    UIImage* newImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
                                                    bounds:screenSize.size
                                      interpolationQuality:kCGInterpolationHigh];
    
    [self.addPhotoButton.imageView  setImage:newImage];
}

#pragma mark ComposeTextViewControllerDelegate
- (void)cancelComposeTextViewController:(ComposeTextViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)doneWithComposeTextViewController:(ComposeTextViewController *)controller
{
    self.pieceTextView.text = controller.textView.text;
    [self dismissViewControllerAnimated:YES completion:^{
        self.doneButton.enabled = [self checkForChanges];
    }];
}

# pragma mark BNLocationManagerDelegate
- (void) locationUpdated
{
    self.addLocationButton.titleLabel.text = self.locationManager.locationStatus;
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
    
    self.keyboardIsShown = NO;
}

- (void)unregisterForKeyboardNotifications
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification 
                                                  object:nil];
    
    self.keyboardIsShown = NO;
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    if (self.keyboardIsShown)
        return; 

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    
    CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];
    
    CGRect viewFrame = self.scrollView.frame;
    self.contentViewDispositionOnKeyboard = self.pieceTextView.frame.origin.y - statusRect.size.height;
    viewFrame.origin.y -= self.contentViewDispositionOnKeyboard;
    self.scrollView.frame = viewFrame;
    
    [UIView commitAnimations];

    self.keyboardIsShown = YES;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillHide:(NSNotification*)aNotification
{
    if(!self.keyboardIsShown)
        return;
        
    self.keyboardIsShown = NO;
    self.contentViewDispositionOnKeyboard = 0;
}


- (IBAction)dismissKeyboard:(id)sender
{
    self.doneButton.enabled = [self checkForChanges];
    
    if (self.pieceTextView.isFirstResponder)
        [self.pieceTextView resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView 
shouldChangeTextInRange:(NSRange)range 
 replacementText:(NSString *)text
{
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return (newLength > MAX_CHAR_IN_PIECE) ? NO : YES;
}

- (BOOL)checkForChanges
{
    if (self.editMode == add)
    {
        if (self.imageChanged
            || ![self.pieceTextView.text isEqualToString:@""])
            return YES;
        else
            return NO;
    } else if (self.editMode == edit)
    {
        if ((self.imageChanged)
            || (![self.pieceTextView.text isEqualToString:self.piece.text]))
            return YES;
        else
            return NO;
    } else
    {
        NSLog(@"ModifySceneViewController_checkForChanges_1");
        return NO;
    }
}


#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // This usually happens when taking a picture from the camera
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:REPLACE_NIL_WITH_EMPTY_STRING(self.pieceTextView.text) forKey:MEM_WARNING_USER_DEFAULTS_TEXT_FIELD];
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end

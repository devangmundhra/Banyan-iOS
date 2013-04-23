//
//  ModifyPieceViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModifyPieceViewController.h"
#import "Piece+Create.h"
#import "Piece+Edit.h"
#import "Piece+Delete.h"
#import "Story+Delete.h"
#import "Story+Edit.h"
#import "Piece_Defines.h"
#import "Story_Defines.h"
#import "SSTextView.h"
#import "SSTextField.h"

@interface ModifyPieceViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet SSTextField *pieceCaptionView;
@property (weak, nonatomic) IBOutlet SSTextView *pieceTextView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet LocationPickerButton *addLocationButton;
@property (weak, nonatomic) IBOutlet MediaPickerButton *addPhotoButton;

@property (strong, nonatomic) NSString *localImageURL;
@property (nonatomic) BOOL imageChanged;

@property (strong, nonatomic) BNFBLocationManager *locationManager;

@property (nonatomic) ModifyPieceViewControllerEditMode editMode;
@property (strong, nonatomic) Piece *backupPiece_;

@end

@implementation ModifyPieceViewController

@synthesize pieceTextView = _pieceTextView;
@synthesize navigationBar = _navigationBar;
@synthesize cancelButton = _cancelButton;
@synthesize doneButton = _doneButton;
@synthesize piece = _piece;
//@synthesize delegate = _delegate;
@synthesize editMode = _editMode;
@synthesize imageChanged = _imageChanged;
@synthesize localImageURL = _localImageURL;
@synthesize locationManager = _locationManager;
@synthesize pieceCaptionView, addLocationButton, addPhotoButton;
@synthesize backupPiece_ = _backupPiece_;

- (id) initWithPiece:(Piece *)piece
{
    if (self = [super initWithNibName:@"ModifyPieceViewController" bundle:nil]) {
        self.piece = piece;
        if (self.piece.remoteStatus == RemoteObjectStatusLocal) {
            self.editMode = ModifyPieceViewControllerEditModeAddPiece;
        } else {
            self.editMode = ModifyPieceViewControllerEditModeEditPiece;
            self.backupPiece_ = [NSEntityDescription insertNewObjectForEntityForName:[[piece entity] name] inManagedObjectContext:[piece managedObjectContext]];
            [self.backupPiece_ cloneFrom:piece];
        }
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.pieceTextView.delegate = self;
    self.pieceTextView.backgroundColor = [UIColor clearColor];    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.editMode == ModifyPieceViewControllerEditModeAddPiece && [self.piece.story.isLocationEnabled boolValue]) {
        [self.locationManager stopUpdatingLocation:self.piece.geocodedLocation];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.editMode == ModifyPieceViewControllerEditModeAddPiece && [self.piece.story.isLocationEnabled boolValue]) {
        self.locationManager = [[BNFBLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager beginUpdatingLocation];
    } else {
        [self.addLocationButton setEnabled:NO];
    }
    
    if (self.piece.geocodedLocation && ![self.piece.geocodedLocation isEqual:[NSNull null]]) {
        [self.addLocationButton locationPickerLocationEnabled:YES];
        [self.addLocationButton setLocationPickerTitle:self.piece.geocodedLocation];
    }
    
    self.pieceCaptionView.delegate = self;
    self.pieceCaptionView.textEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5);
    self.pieceTextView.placeholder = @"Enter more details here";
    self.pieceTextView.textColor = BANYAN_BLACK_COLOR;
    self.addLocationButton.delegate = self;
    self.addPhotoButton.delegate = self;
    
    if (self.editMode == ModifyPieceViewControllerEditModeEditPiece)
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
        self.pieceCaptionView.text = self.piece.shortText;
        self.pieceTextView.text = self.piece.longText;
        self.navigationBar.topItem.title = @"Edit Piece";
    } else {
        self.navigationBar.topItem.title = @"Add Piece";
    }
    
    self.doneButton.enabled = NO;
    
    self.imageChanged = NO;
    
    [self registerForKeyboardNotifications];

    CGSize screenSize = [UIScreen mainScreen].applicationFrame.size;
    self.scrollView.contentSize = CGSizeMake(screenSize.width,
                                             screenSize.height
                                             - self.navigationBar.frame.size.height);
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
    [self setAddLocationButton:nil];
    [self setAddPhotoButton:nil];
    [self setScrollView:nil];
    [self setPieceCaptionView:nil];
    [super viewDidUnload]; 
    [self unregisterForKeyboardNotifications];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark target actions from navigation bar

- (void)deleteBackupPiece
{
    if (self.backupPiece_) {
        NSManagedObjectContext *moc = self.backupPiece_.managedObjectContext;
        [moc deleteObject:self.backupPiece_];
        NSError *error;
        [moc save:&error];
        self.backupPiece_ = nil;
    }
}

- (void)restoreBackupPiece:(BOOL)upload {
    if (self.backupPiece_) {
        [self.piece cloneFrom:self.backupPiece_];
    }
}

- (IBAction)cancel:(UIBarButtonItem *)sender
{
    if (self.editMode == ModifyPieceViewControllerEditModeEditPiece) {
        [self restoreBackupPiece:NO];
    }
    
	//remove the original piece in case of local draft unsaved
	if (self.editMode == ModifyPieceViewControllerEditModeAddPiece)
		[self.piece remove];
    
	self.piece = nil; // Just in case
    [self dismissEditView];
}

// Done modifying piece. Now save all the changes.
- (IBAction)done:(UIBarButtonItem *)sender 
{
    self.piece.longText = self.pieceTextView.text;
    self.piece.shortText = self.pieceCaptionView.text;
    self.piece.imageURL = self.localImageURL;
    
    if (self.editMode == ModifyPieceViewControllerEditModeAddPiece)
    {
        if ([self.piece.story.isLocationEnabled boolValue] == YES) {
            if (self.locationManager.location) {
                self.piece.latitude = self.locationManager.location.location.latitude;
                self.piece.longitude = self.locationManager.location.location.longitude;
                self.piece.geocodedLocation = self.locationManager.location.name;
            }
        }
        
        [Piece createNewPiece:self.piece afterPiece:nil];
        NSLog(@"New piece %@ saved", self.piece);
        [TestFlight passCheckpoint:@"New piece created successfully"];
    }
    else if (self.editMode == ModifyPieceViewControllerEditModeEditPiece)
    {
        self.piece.longText = self.pieceTextView.text;
        if (self.imageChanged) {
            self.piece.imageURL = self.localImageURL;
            self.piece.imageChanged = [NSNumber numberWithBool:YES];
            //            self.piece.image = self.imageView.image;
        }
        [Piece editPiece:self.piece];
    }
    else {
        assert(false);
        NSLog(@"ModifyPieceViewController_No valid edit mode");
    }
    if (self.delegate)
        [self.delegate modifyPieceViewController:self didFinishAddingPiece:self.piece];
    
    [self dismissEditView];
}

- (IBAction)deletePieceAlert:(UIBarButtonItem *)sender
{
    UIAlertView *alertView = nil;
    alertView = [[UIAlertView alloc] initWithTitle:@"Delete Piece"
                                           message:@"Do you want to delete this piece?"
                                          delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    
    [alertView show];
}

- (void)deletePiece:(UIBarButtonItem *)sender
{
    NSLog(@"ModifyPieceViewController_Deleting piece");
    [Piece deletePiece:self.piece];
    [self dismissEditView];
    [TestFlight passCheckpoint:@"Piece deleted"];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==1) {
        [self deletePiece:nil];
    }
}

#pragma mark MediaPickerButtonDelegate methods
- (void) mediaPickerButtonTapped:(MediaPickerButton *)sender
{
    [self dismissKeyboard:sender];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Modify Photo"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:self.localImageURL ? @"Delete Photo" : nil
                                                    otherButtonTitles:nil];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        [actionSheet addButtonWithTitle:MediaPickerControllerSourceTypeCamera];
    [actionSheet addButtonWithTitle:MediaPickerControllerSourceTypePhotoLib];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
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
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:MediaPickerControllerSourceTypeCamera]) {
        MediaPickerViewController *mediaPicker = [[MediaPickerViewController alloc] init];
        mediaPicker.delegate = self;
        [self addChildViewController:mediaPicker];
        [mediaPicker shouldStartCameraController];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:MediaPickerControllerSourceTypePhotoLib]) {
        MediaPickerViewController *mediaPicker = [[MediaPickerViewController alloc] init];
        mediaPicker.delegate = self;
        [self addChildViewController:mediaPicker];
        [mediaPicker shouldStartPhotoLibraryPickerController];
    }
    else {
        NSLog(@"ModifyPieceViewController_actionSheetclickedButtonAtIndex %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
    }
}

#pragma mark MediaPickerViewControllerDelegate methods
- (void) mediaPicker:(MediaPickerViewController *)mediaPicker finishedPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:MediaPickerViewControllerInfoImage];
    self.localImageURL = [(NSURL *)[info objectForKey:MediaPickerViewControllerInfoURL] absoluteString];
    
    [self.addPhotoButton.imageView  cancelImageRequestOperation];
    self.imageChanged = YES;
    [NSThread detachNewThreadSelector:@selector(useImage:) toTarget:self withObject:image];
    self.doneButton.enabled = [self checkForChanges];
}

- (void)mediaPickerDidCancel:(MediaPickerViewController *)mediaPicker
{
    self.localImageURL = nil;
    self.imageChanged = NO;
}

- (void)useImage:(UIImage *)image {
    // Create a graphics image context    
    UIImage* newImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
                                                    bounds:self.addPhotoButton.frame.size
                                      interpolationQuality:kCGInterpolationHigh];
    
    [self.addPhotoButton.imageView setImage:newImage];
}

# pragma mark LocationPickerButtonDelegate
- (void)locationPickerButtonTapped:(LocationPickerButton *)sender
{
    [self.addLocationButton locationPickerLocationEnabled:YES];
    [self.locationManager showPlacePickerViewController];
}

- (void)locationPickerButtonToggleLocationEnable:(LocationPickerButton *)sender
{
    [self.addLocationButton locationPickerLocationEnabled:[self.piece.story.isLocationEnabled boolValue]];
    if (self.piece.story.isLocationEnabled) {
        [self.locationManager showPlacePickerViewController];
    } else {
        [self.locationManager stopUpdatingLocation:@"Add Location"];
    }
}

# pragma mark BNLocationManagerDelegate
- (void) locationUpdated
{
    [self.addLocationButton locationPickerLocationUpdatedWithLocation:self.locationManager.location];
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

}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillHide:(NSNotification*)aNotification
{
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}


- (IBAction)dismissKeyboard:(id)sender
{
    self.doneButton.enabled = [self checkForChanges];
    
    if (self.pieceTextView.isFirstResponder)
        [self.pieceTextView resignFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.doneButton.enabled = [self checkForChanges];
}

- (BOOL)checkForChanges
{
    if (self.editMode == ModifyPieceViewControllerEditModeAddPiece)
    {
        if (self.imageChanged
            || ![self.pieceTextView.text isEqualToString:@""]
            || ![self.pieceCaptionView.text isEqualToString:@""])
            return YES;
        else
            return NO;
    } else if (self.editMode == ModifyPieceViewControllerEditModeEditPiece)
    {
        if ((self.imageChanged)
            || (![self.pieceTextView.text isEqualToString:self.piece.longText])
            || (![self.pieceCaptionView.text isEqualToString:self.piece.shortText]))
            return YES;
        else
            return NO;
    } else
    {
        NSLog(@"ModifyPieceViewController_checkForChanges_1");
        return NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.doneButton.enabled = [self checkForChanges];
}

#pragma mark Methods to interface between views
- (void) dismissEditView
{
    [self deleteBackupPiece];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end

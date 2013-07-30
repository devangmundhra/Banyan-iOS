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
#import "Media.h"

@interface ModifyPieceViewController ()

@property (weak, nonatomic) IBOutlet UIButton *storyTitleButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet SSTextField *pieceCaptionView;
@property (weak, nonatomic) IBOutlet SSTextView *pieceTextView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet LocationPickerButton *addLocationButton;
@property (weak, nonatomic) IBOutlet MediaPickerButton *addPhotoButton;

@property (strong, nonatomic) BNAudioRecorder *audioRecorder;
@property (weak, nonatomic) IBOutlet UIView *audioPickerView;

@property (strong, nonatomic) BNFBLocationManager *locationManager;

@property (nonatomic) ModifyPieceViewControllerEditMode editMode;

@property (strong, nonatomic) Piece *backupPiece_;
@property (nonatomic, strong) NSOrderedSet *backupMedia_;

@property (strong, nonatomic) NSMutableSet *mediaToDelete;

@end

@implementation ModifyPieceViewController

@synthesize pieceTextView = _pieceTextView;
@synthesize navigationBar = _navigationBar;
@synthesize cancelButton = _cancelButton;
@synthesize doneButton = _doneButton;
@synthesize piece = _piece;
@synthesize delegate = _delegate;
@synthesize editMode = _editMode;
@synthesize locationManager = _locationManager;
@synthesize pieceCaptionView, addLocationButton, addPhotoButton;
@synthesize backupPiece_ = _backupPiece_;
@synthesize audioPickerView = _audioPickerView;
@synthesize audioRecorder = _audioRecorder;
@synthesize mediaToDelete;
@synthesize storyTitleButton = _storyTitleButton;
@synthesize backupMedia_ = _backupMedia_;

- (id) initWithPiece:(Piece *)piece
{
    if (self = [super initWithNibName:@"ModifyPieceViewController" bundle:nil]) {
        self.piece = piece;
        if (self.piece.remoteStatus == RemoteObjectStatusLocal) {
            self.editMode = ModifyPieceViewControllerEditModeAddPiece;
        } else {
            self.editMode = ModifyPieceViewControllerEditModeEditPiece;
            self.backupPiece_ = [NSEntityDescription insertNewObjectForEntityForName:[[piece entity] name] inManagedObjectContext:[piece managedObjectContext]];
            self.backupMedia_ = [NSOrderedSet orderedSetWithOrderedSet:self.piece.media];
            [self.backupPiece_ cloneFrom:piece];
        }
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.pieceTextView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.view endEditing:YES];
    [self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unregisterForKeyboardNotifications];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.editMode == ModifyPieceViewControllerEditModeAddPiece && self.piece.story.isLocationEnabled) {
        [self.locationManager stopUpdatingLocation:self.piece.location.name];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.storyTitleButton.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:16];
    [self.storyTitleButton setAttributedTitle:[[NSAttributedString alloc] initWithString:self.piece.story.title
                                                                              attributes:@{NSUnderlineStyleAttributeName: @1,
                                                                                           NSForegroundColorAttributeName: BANYAN_WHITE_COLOR}] forState:UIControlStateNormal];
    self.storyTitleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    if (self.editMode == ModifyPieceViewControllerEditModeAddPiece) {
        // Only if this is a new piece should we allow changing the story for the piece.
        self.storyTitleButton.showsTouchWhenHighlighted = YES;
        self.storyTitleButton.userInteractionEnabled = YES;
    } else {
        self.storyTitleButton.userInteractionEnabled = NO;
    }
    
    mediaToDelete = [NSMutableSet set];
    
    self.locationManager = [[BNFBLocationManager alloc] init];
    self.locationManager.delegate = self;
    // If story has location enabled, only then try to get the location
    if (self.piece.story.isLocationEnabled) {
        [self.locationManager beginUpdatingLocation];
        self.locationManager.location = self.piece.location;
    }
    
    if ([self.piece.location.name length]) {
        [self.addLocationButton locationPickerLocationEnabled:YES];
        [self.addLocationButton setLocationPickerTitle:self.piece.location.name];
    }
    self.addLocationButton.delegate = self;
    
    self.audioRecorder = [[BNAudioRecorder alloc] init];
    [self addChildViewController:self.audioRecorder];
    [self.audioPickerView addSubview:self.audioRecorder.view];
    self.audioRecorder.view.frame = self.audioPickerView.bounds;
    [self.audioRecorder didMoveToParentViewController:self];
    
    self.pieceCaptionView.delegate = self;
    self.pieceCaptionView.textEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    self.pieceCaptionView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.pieceCaptionView.font = [UIFont fontWithName:@"Roboto-BoldCondensed" size:26];
    self.pieceCaptionView.textAlignment = NSTextAlignmentLeft;
    
    self.pieceTextView.placeholder = @"Enter more details here";
    self.pieceTextView.textColor = BANYAN_BLACK_COLOR;
    self.pieceTextView.font = [UIFont fontWithName:@"Roboto" size:18];
    self.pieceTextView.textAlignment = NSTextAlignmentLeft;

    self.addPhotoButton.delegate = self;
    
    if (self.editMode == ModifyPieceViewControllerEditModeEditPiece)
    {
//        NSOrderedSet *imageMediaSet = [Media getAllMediaOfType:@"image" inMediaSet:self.piece.media];
//        
//        if (imageMediaSet) {
//            [imageMediaSet enumerateObjectsUsingBlock:^(Media *media, NSUInteger idx, BOOL *stop) {
//                [self.addPhotoButton addImageMedia:media];
//            }];
//        }
        [self.addPhotoButton reloadList];
        
        Media *audioMedia = [Media getMediaOfType:@"audio" inMediaSet:self.piece.media];
        if (audioMedia ) {
            UIButton *deleteAudioButton = [UIButton buttonWithType:UIButtonTypeCustom];
            deleteAudioButton.frame = self.audioPickerView.bounds;
            [deleteAudioButton setTitle:@"Delete audio clip" forState:UIControlStateNormal];
            [deleteAudioButton setBackgroundColor:BANYAN_RED_COLOR];
            [deleteAudioButton addTarget:self action:@selector(deleteAudioAlert:) forControlEvents:UIControlEventTouchUpInside];
            [self.audioPickerView addSubview:deleteAudioButton];
        }
        
        self.pieceCaptionView.text = self.piece.shortText;
        self.pieceTextView.text = self.piece.longText;
        self.navigationBar.topItem.title = @"Edit Piece";
    } else {
        self.navigationBar.topItem.title = @"Add Piece";
    }
    
    self.doneButton.enabled = [self checkForChanges];

    CGSize screenSize = [UIScreen mainScreen].applicationFrame.size;
    self.scrollView.contentSize = CGSizeMake(screenSize.width,
                                             screenSize.height
                                             - self.navigationBar.frame.size.height);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark target actions from navigation bar

- (void)deleteBackupPiece
{
    if (self.backupPiece_) {
        [self.backupPiece_ remove];
        self.backupPiece_ = nil;
    }
}

- (void)restoreBackupPiece:(BOOL)upload {    
    if (self.backupPiece_) {
        [self.piece cloneFrom:self.backupPiece_];
        
        // Restore the media
        if (![self.backupMedia_ isEqualToOrderedSet:self.piece.media]) {
            // Remove any new media that might have been added
            NSMutableOrderedSet *mediaToRemove = [NSMutableOrderedSet orderedSetWithOrderedSet:self.piece.media];
            [mediaToRemove minusOrderedSet:self.backupMedia_];
            for (Media *media in mediaToRemove) {
                [media remove];
            }
            assert([self.piece.media intersectsOrderedSet:self.backupMedia_] && [self.backupMedia_ intersectsOrderedSet:self.piece.media]);
            // Set the old media back again in case the ordering was changed
            [self.piece setMedia:self.backupMedia_];
        }
    }
}

- (IBAction)cancel:(UIBarButtonItem *)sender
{
    [self restoreBackupPiece:NO];
    
	//remove the original piece in case of local draft unsaved
	if (self.editMode == ModifyPieceViewControllerEditModeAddPiece)
		[self.piece remove];
    
	self.piece = nil; // Just in case
    [self dismissEditView];
}

// Done modifying piece. Now save all the changes.
- (IBAction)done:(UIBarButtonItem *)sender 
{
    // So that ReadPieceVC's KVO are not fired unnecessarily
    if (![self.piece.longText isEqualToString:self.pieceTextView.text])
        self.piece.longText = self.pieceTextView.text;
    if (![self.piece.shortText isEqualToString:self.pieceCaptionView.text])
        self.piece.shortText = self.pieceCaptionView.text;
    
    if (self.piece.story.isLocationEnabled == YES ) {
        self.piece.location = (FBGraphObject<FBGraphPlace> *)self.locationManager.location;
    }
    
    // Get the recording from audioRecorder
    NSURL *audioRecording = [self.audioRecorder getRecording];
    if (audioRecording) {
        Media *media = [Media newMediaForObject:self.piece];
        media.mediaType = @"audio";
        media.localURL = [audioRecording absoluteString];
    }
    
    BOOL anyMediaDeleted = mediaToDelete.count;
    
    // Delete any media that were indicated to be deleted
    for (Media *media in mediaToDelete) {
        // If its a local image, don't delete it
        if ([media.remoteURL length]) {
            [media deleteWitSuccess:nil
                            failure:^(NSError *error) {
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error deleting %@ when editing piece %@", media.mediaTypeName, self.piece.shortText.length ? self.piece.shortText : @""]
                                                                message:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }];
        }
        else
            [media remove];
    }
    
    // If there are multiple image media, convert them into a gif
    NSOrderedSet *imageMediaSet = [Media getAllMediaOfType:@"image" inMediaSet:self.piece.media];
    NSOrderedSet *backupImageMediaSet = [Media getAllMediaOfType:@"image" inMediaSet:self.backupMedia_];
    // Gif should be created only if number if images is greater than 2
    // And if we are adding a new piece
    //   Or the images and order of images are not the same
    //   Or any media should not have been deleted when the piece is being edited
    BOOL shouldCreateNewGif = (imageMediaSet.count > 1) && (self.editMode == ModifyPieceViewControllerEditModeAddPiece || ![imageMediaSet isEqualToOrderedSet:backupImageMediaSet] || (self.editMode == ModifyPieceViewControllerEditModeEditPiece && anyMediaDeleted));
    
    // If a new gif should be deleted or if there is only 1 or 0 images so that a previous gif should be deleted
    if (shouldCreateNewGif || imageMediaSet.count <= 1) {
        Media *gifMedia = [Media getMediaOfType:@"gif" inMediaSet:self.piece.media];
        if (gifMedia) {
            if ([gifMedia.remoteURL length]) {
                [gifMedia deleteWitSuccess:nil
                                   failure:^(NSError *error) {
                                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error deleting %@ when editing piece %@", gifMedia.mediaTypeName, self.piece.shortText.length ? self.piece.shortText : @""]
                                                                                       message:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]
                                                                                      delegate:nil
                                                                             cancelButtonTitle:@"OK"
                                                                             otherButtonTitles:nil];
                                       [alert show];
                                   }];
            } else
                [gifMedia remove];
        }
    }
    
    if (self.editMode == ModifyPieceViewControllerEditModeAddPiece)
    {
        [Piece createNewPiece:self.piece];
        NSLog(@"New piece %@ saved", self.piece);
        [TestFlight passCheckpoint:@"New piece created successfully"];
    }
    else if (self.editMode == ModifyPieceViewControllerEditModeEditPiece)
    {
        // If the piece's story has changed, update the old one and the new one
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

- (IBAction)deleteAudioAlert:(UIButton *)sender
{
    UIAlertView *alertView = nil;
    alertView = [[UIAlertView alloc] initWithTitle:@"Delete Audio"
                                           message:@"Do you want to delete this audio piece?"
                                          delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    
    [alertView show];
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

- (IBAction)storyChangeButtonPressed:(id)sender
{
    NSLog(@"Current story is %@", self.piece.story.title);
    StoryPickerViewController *vc = [[StoryPickerViewController alloc] initWithStyle:UITableViewStylePlain];
    vc.delegate = self;
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nvc animated:YES completion:nil];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Delete Piece"] && buttonIndex==1) {
        [self deletePiece:nil];
        return;
    }
    if ([alertView.title isEqualToString:@"Delete Audio"] && buttonIndex==1) {
        Media *audioMedia = [Media getMediaOfType:@"audio" inMediaSet:self.piece.media];
        [mediaToDelete addObject:audioMedia];
        // Remove the delete button
        [[[self.audioPickerView subviews] lastObject] removeFromSuperview];
        self.doneButton.enabled = YES;
        return;
    }
}

#pragma mark MediaPickerButtonDelegate methods
- (void) addNewMedia:(MediaPickerButton *)sender
{
    [self dismissKeyboard:sender];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Modify Photo"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        [actionSheet addButtonWithTitle:MediaPickerControllerSourceTypeCamera];
    [actionSheet addButtonWithTitle:MediaPickerControllerSourceTypePhotoLib];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

- (void) deletePreviousMedia:(Media *)media
{
    [mediaToDelete addObject:media];
    [self.addPhotoButton reloadList];
    self.doneButton.enabled = YES;
}

- (NSOrderedSet *)listOfMediaForMediaPickerButton
{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithOrderedSet:[Media getAllMediaOfType:@"image" inMediaSet:self.piece.media]];
    [set minusSet:mediaToDelete];
    return set;
}

- (void) updateMediaFromNumber:(NSUInteger)fromNumber toNumber:(NSUInteger)toNumber
{
    Media *media = [self.piece.media objectAtIndex:fromNumber];
    [self.piece removeObjectFromMediaAtIndex:fromNumber];
    [self.piece insertObject:media inMediaAtIndex:toNumber];
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
        // DO NOTHING ON DESTROY (Handled seperately)
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
    Media *media = [Media newMediaForObject:self.piece];
    media.mediaType = @"image";
    media.localURL = [(NSURL *)[info objectForKey:MediaPickerViewControllerInfoURL] absoluteString];
    [self.addPhotoButton reloadList];
    
    self.doneButton.enabled = [self checkForChanges];
}

- (void)mediaPickerDidCancel:(MediaPickerViewController *)mediaPicker
{
    
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

# pragma mark StoryPickerViewControllerDelegate
- (void) storyPickerViewControllerDidPickStory:(Story *)story
{
    // A new story was picked.
    // Change the story of this piece to the new story
    self.piece.story = story;
    [self.storyTitleButton setAttributedTitle:[[NSAttributedString alloc] initWithString:self.piece.story.title
                                                                              attributes:@{NSUnderlineStyleAttributeName: @1,
                                                                                           NSForegroundColorAttributeName: BANYAN_WHITE_COLOR}] forState:UIControlStateNormal];
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
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
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
    self.doneButton.enabled = [self checkForChanges];
    
    if (self.pieceTextView.isFirstResponder)
        [self.pieceTextView resignFirstResponder];
}

- (BOOL)checkForChanges
{
    // TODO check with backup and return appropriately
    return YES;
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.doneButton.enabled = [self checkForChanges];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.doneButton.enabled = [self checkForChanges];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
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

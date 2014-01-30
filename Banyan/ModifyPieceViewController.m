//
//  ModifyPieceViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/17/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "ModifyPieceViewController.h"
#import "Piece+Create.h"
#import "Piece+Edit.h"
#import "Piece+Delete.h"
#import "Story+Delete.h"
#import "Story+Edit.h"
#import "Piece_Defines.h"
#import "Story_Defines.h"
#import "Media.h"
#import "AVCamViewController.h"
#import "UIPlaceHolderTextView.h"
#import "BNTextField.h"
#import "LocationPickerButton.h"
#import "BNAudioRecorderView.h"
#import "UIImage+ResizeAdditions.h"
#import "GooglePlacePickerViewController.h"

@interface ModifyPieceViewController (LocationPickerButtonDelegate) <LocationPickerButtonDelegate>

@end

@interface ModifyPieceViewController (GooglePlacesViewControllerDelegate) <GooglePlacesViewControllerDelegate>

@end

@interface ModifyPieceViewController (AddPhotoButtonActions)
- (IBAction)addPhotoButtonTappedForCamera:(id)sender;
- (IBAction)addPhotoButtonTappedForGallery:(id)sender;
- (IBAction)addPhotoButtonTappedToDeleteImage:(id)sender;
@end

@interface ModifyPieceViewController (AVCamViewControllerDelegate) <AVCamViewControllerDelegate>
- (void) dismissAVCamViewController:(AVCamViewController *)viewController;
@end

@interface ModifyPieceViewController (MediaPickerViewControllerDelegate) <MediaPickerViewControllerDelegate>
@end

@interface ModifyPieceViewController ()

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIButton *storyTitleButton;
@property (strong, nonatomic) IBOutlet BNTextField *pieceCaptionView;
@property (strong, nonatomic) IBOutlet UIPlaceHolderTextView *pieceTextView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet LocationPickerButton *addLocationButton;
@property (strong, nonatomic) IBOutlet SingleImagePickerButton *addPhotoButton;

@property (strong, nonatomic) BNAudioRecorder *audioRecorder;
@property (strong, nonatomic) IBOutlet BNAudioRecorderView *audioPickerView;

@property (nonatomic) ModifyPieceViewControllerEditMode editMode;

@property (strong, nonatomic) NSMutableSet *mediaToDelete;
@property (strong, nonatomic) NSManagedObjectContext *scratchMOC;;

@property (strong, nonatomic) IBOutlet UIToolbar *textViewInputAccessoryView;

@property (strong, nonatomic) AVCamViewController *camViewController;
@property (nonatomic) CGSize kbSize;

@property (strong, nonatomic) NSManagedObjectID *storyID;

@end

@implementation ModifyPieceViewController

@synthesize pieceTextView = _pieceTextView;
@synthesize doneButton = _doneButton;
@synthesize piece = _piece;
@synthesize delegate = _delegate;
@synthesize editMode = _editMode;
@synthesize pieceCaptionView = _pieceCaptionView;
@synthesize addLocationButton, addPhotoButton;
@synthesize audioPickerView = _audioPickerView;
@synthesize audioRecorder = _audioRecorder;
@synthesize mediaToDelete;
@synthesize storyTitleButton = _storyTitleButton;
@synthesize textViewInputAccessoryView = _textViewInputAccessoryView;
@synthesize camViewController = _camViewController;
@synthesize kbSize;
@synthesize scratchMOC = _scratchMOC;
@synthesize storyID = _storyID;

#define TEXT_INSETS 5
#define VIEW_INSETS 8
#define CORNER_RADIUS 8
#define SUBVIEW_OPACITY 0.5

- (id) initWithPiece:(Piece *)piece
{
    if (self = [super init]) {
        // Use the NSPrivateQueueConcurrencyType MOC here. This is because if we use the NSMainQueueConcurrencyType and the piece is deleted from
        // the PersistentStoreCoord MOC, it results in a Cocoa Error 1600. For example, in this scenario-
        // 1. Create a story and a piece (say from simulator)
        // 2. Refresh the story list to get the story and piece from server
        // 3. Delete the story from the simulator
        // 4. Refrsh the story list from the server on the device, and while refreshing, open the "addAPiece" VC.
        // 5. When the refresh compeltes, there will be a CocoaError 1600.
        // This does not happen in NSPrivateQueueConcurrencyType
        self.scratchMOC = [[RKManagedObjectStore defaultStore] newChildManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType tracksChanges:YES];
        NSLog(@"Scratch MOC for modify piece vc: %@", self.scratchMOC);
        self.piece = (Piece *)[piece cloneIntoNSManagedObjectContext:self.scratchMOC];
        // Just in case the connection between the piece and story is lost (say because the piece is currently being created and the story is refreshed),
        // this context will still have the correct relationship
        [piece.story cloneIntoNSManagedObjectContext:self.scratchMOC];
        self.storyID = piece.story.objectID;
        if (self.piece.remoteStatus == RemoteObjectStatusLocal) {
            self.editMode = ModifyPieceViewControllerEditModeAddPiece;
        } else {
            self.editMode = ModifyPieceViewControllerEditModeEditPiece;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view
    self.edgesForExtendedLayout = UIRectEdgeNone;

    // Get a reference to weak self for use in blocks
    __weak ModifyPieceViewController *wself = self;

    [self.view setBackgroundColor:BANYAN_WHITE_COLOR];
    
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    [self.navigationItem setRightBarButtonItem:self.doneButton];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];

    // Allocate the accessory view for the keyboard
    self.textViewInputAccessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 44.0f)];
    self.textViewInputAccessoryView.backgroundColor = [UIColor grayColor];
    self.textViewInputAccessoryView.translucent = YES;
    NSMutableArray *toolbarItems = [NSMutableArray array];
    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
//    UIBarButtonItem *tagButton = [[UIBarButtonItem alloc] initWithTitle:@"#tag"
//                                                                  style:UIBarButtonItemStyleBordered
//                                                                 target:self
//                                                                 action:@selector(addHashTag:)];
//    [toolbarItems addObject:tagButton];
//    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil]];
    UIBarButtonItem *disKbButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(dismissKeyboard:)];
    [toolbarItems addObject:disKbButton];
    [self.textViewInputAccessoryView setItems:toolbarItems];

    CGRect frame = self.view.bounds;
    self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
    [self.scrollView setContentSize:frame.size];
    [self.scrollView setBackgroundColor:[BANYAN_WHITE_COLOR colorWithAlphaComponent:0.4]];
    [self.view addSubview:self.scrollView];
    
    frame = self.scrollView.bounds;
    frame.size.height = 34.0f;
    frame.origin.x = VIEW_INSETS;
    frame.origin.y += VIEW_INSETS;
    frame.size.width -= 2*VIEW_INSETS;
    self.storyTitleButton = [[UIButton alloc] initWithFrame:frame];
    self.storyTitleButton.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:16];
    self.storyTitleButton.titleLabel.numberOfLines = 2;
    self.storyTitleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.storyTitleButton addTarget:self action:@selector(storyChangeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.storyTitleButton setBackgroundColor:[BANYAN_DARKGRAY_COLOR colorWithAlphaComponent:SUBVIEW_OPACITY]];
    [self.storyTitleButton.layer setCornerRadius:CORNER_RADIUS];
    if (self.editMode == ModifyPieceViewControllerEditModeAddPiece) {
        // Only if this is a new piece should we allow changing the story for the piece.
        self.storyTitleButton.showsTouchWhenHighlighted = YES;
        self.storyTitleButton.userInteractionEnabled = YES;
    } else {
        self.storyTitleButton.userInteractionEnabled = NO;
    }
    [self updateStoryTitle];
    [self.scrollView addSubview:self.storyTitleButton];

    frame.origin.y = CGRectGetMaxY(self.storyTitleButton.frame) + VIEW_INSETS;
    frame.size.height = 44.0f;
    self.pieceCaptionView = [[BNTextField alloc] initWithFrame:frame];
    self.pieceCaptionView.delegate = self;
    self.pieceCaptionView.placeholder = @"What is this piece about?";
    self.pieceCaptionView.textEdgeInsets = UIEdgeInsetsMake(0, TEXT_INSETS, 0, TEXT_INSETS);
    self.pieceCaptionView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.pieceCaptionView.font = [UIFont fontWithName:@"Roboto-BoldCondensed" size:26];
    self.pieceCaptionView.textAlignment = NSTextAlignmentLeft;
    self.pieceCaptionView.backgroundColor = [BANYAN_WHITE_COLOR colorWithAlphaComponent:SUBVIEW_OPACITY];
    self.pieceCaptionView.returnKeyType = UIReturnKeyDone;
    [self.pieceCaptionView.layer setCornerRadius:CORNER_RADIUS];
    [self.scrollView addSubview:self.pieceCaptionView];
    
    frame.origin.y = CGRectGetMaxY(self.pieceCaptionView.frame) + VIEW_INSETS;
    frame.size.height = 88.0f;
    self.pieceTextView = [[UIPlaceHolderTextView alloc] initWithFrame:frame];
    self.pieceTextView.placeholder = @"Enter more details here";
    self.pieceTextView.textColor = BANYAN_BLACK_COLOR;
    self.pieceTextView.font = [UIFont fontWithName:@"Roboto" size:18];
    self.pieceTextView.textAlignment = NSTextAlignmentLeft;
    self.pieceTextView.inputAccessoryView = self.textViewInputAccessoryView;
    self.pieceTextView.backgroundColor = [BANYAN_WHITE_COLOR colorWithAlphaComponent:SUBVIEW_OPACITY];
    [self.pieceTextView.layer setCornerRadius:CORNER_RADIUS];
    self.pieceTextView.userInteractionEnabled = YES;
    [self.scrollView addSubview:self.pieceTextView];
    
    // Set the camViewController below scrollView. Do this in a background thread as AVCamViewController
    // might take a long time to load and init
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!wself) return;
        wself.camViewController = [[AVCamViewController alloc] initWithNibName:@"AVCamViewController" bundle:nil];
        wself.camViewController.delegate = wself;
        [wself.camViewController willMoveToParentViewController:wself];
        [wself addChildViewController:wself.camViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!wself) return;
            wself.camViewController.view.frame = wself.view.bounds;
            [wself.view insertSubview:wself.camViewController.view belowSubview:wself.scrollView];
            [wself.camViewController hideAVCamViewControllerControls];
            [wself.camViewController didMoveToParentViewController:wself];
        });
    });

    frame.origin.y = CGRectGetMaxY(self.pieceTextView.frame) + VIEW_INSETS;
    frame.size.height = 100.0f;
    self.addPhotoButton = [[SingleImagePickerButton alloc] initWithFrame:frame];
    [self.addPhotoButton addTargetForCamera:self action:@selector(addPhotoButtonTappedForCamera:)];
    [self.addPhotoButton addTargetForPhotoGallery:self action:@selector(addPhotoButtonTappedForGallery:)];
    [self.addPhotoButton addTargetToDeleteImage:self action:@selector(addPhotoButtonTappedToDeleteImage:)];
    [self.addPhotoButton.layer setCornerRadius:CORNER_RADIUS];
    [self.addPhotoButton setBackgroundColor:[BANYAN_WHITE_COLOR colorWithAlphaComponent:SUBVIEW_OPACITY]];
    [self.scrollView addSubview:self.addPhotoButton];
    mediaToDelete = [NSMutableSet set];

    frame.origin.y = CGRectGetMaxY(self.addPhotoButton.frame) + VIEW_INSETS;
    frame.size.height = 44.0f;
    self.audioPickerView = [[BNAudioRecorderView alloc] initWithFrame:frame];
    [self.audioPickerView.layer setCornerRadius:CORNER_RADIUS];
    self.audioPickerView.clipsToBounds = YES;
    [self.audioPickerView setBackgroundColor:[BANYAN_BROWN_COLOR colorWithAlphaComponent:SUBVIEW_OPACITY]];
    [self.scrollView addSubview:self.audioPickerView];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!wself) return;
        wself.audioRecorder = [[BNAudioRecorder alloc] init];
        wself.audioPickerView.delegate = wself.audioRecorder;
    });

    frame.origin.y = CGRectGetMaxY(self.audioPickerView.frame) + VIEW_INSETS;
    frame.size.height = 44.0f;
    self.addLocationButton = [[LocationPickerButton alloc] initWithFrame:frame];
    [self.addLocationButton.layer setCornerRadius:CORNER_RADIUS];
    if ([self.piece.location.name length]) {
        [self.addLocationButton locationPickerLocationEnabled:YES];
        [self.addLocationButton setLocationPickerTitle:self.piece.location.name];
    }
    [self.addLocationButton setBackgroundColor:[BANYAN_WHITE_COLOR colorWithAlphaComponent:SUBVIEW_OPACITY]];
    self.addLocationButton.delegate = self;
    [self.scrollView addSubview:self.addLocationButton];
    
    if (self.editMode == ModifyPieceViewControllerEditModeEditPiece)
    {
        Media *audioMedia = [Media getMediaOfType:@"audio" inMediaSet:self.piece.media];
        if (audioMedia ) {
            UIButton *deleteAudioButton = [UIButton buttonWithType:UIButtonTypeCustom];
            deleteAudioButton.frame = self.audioPickerView.bounds;
            [deleteAudioButton setTitle:@"Delete audio clip" forState:UIControlStateNormal];
            [deleteAudioButton setBackgroundColor:BANYAN_RED_COLOR];
            [deleteAudioButton addTarget:self action:@selector(deleteAudioAlert:) forControlEvents:UIControlEventTouchUpInside];
            [self.audioPickerView addSubview:deleteAudioButton];
        }
        
        // Cover image
        Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.piece.media];
        
        if (imageMedia) {
            [imageMedia getImageForMediaWithSuccess:^(UIImage *image) {
                [self.addPhotoButton setImage:image];
            } failure:^(NSError *error) {
                NSLog(@"%s Error in getting image for piece (id: %@ text: %@)", __PRETTY_FUNCTION__, self.piece.bnObjectId, self.piece.shortText);
                [self.addPhotoButton unsetImage];
            }];
        } else {
            [self.addPhotoButton unsetImage];
        }
        
        self.pieceCaptionView.text = self.piece.shortText;
        self.pieceTextView.text = self.piece.longText;
        self.title = @"Edit Piece";
    } else {
        self.title = @"Add Piece";
    }
    
    self.doneButton.enabled = [self checkForChanges];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark target actions from navigation bar

- (IBAction)cancel:(UIBarButtonItem *)sender
{
	//remove the original piece in case of local draft unsaved
	if (self.editMode == ModifyPieceViewControllerEditModeAddPiece || self.piece.remoteStatus == RemoteObjectStatusLocal)
		[self.piece remove];
    
	self.piece = nil; // Just in case
    [self dismissEditViewWithCompletionBlock:nil];
}

// Done modifying piece. Now save all the changes.
- (IBAction)done:(UIBarButtonItem *)sender 
{
    // This is needed because it is possible that a piece creation was just started while the
    // stories were being refreshed, in which case piece.story would be nil (since the refreshed
    // story will not have the piece being created). In this case, the original story
    // should be refetched and joined with the piece
    if (!self.piece.story) {
        Story *story = (Story *)[self.scratchMOC objectWithID:self.storyID];
        if (story.isDeleted || story.hasBeenDeleted) {
            [[[UIAlertView alloc] initWithTitle:@"This story has been deleted"
                                        message:[NSString stringWithFormat:@"The story \"%@\" was deleted in the server and it can not be edited", story.title]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil]
             show];
            [self cancel:nil];
            return;
        }
        self.piece.story = story;
    }
    
    if (self.piece.isDeleted || self.piece.hasBeenDeleted) {
        [[[UIAlertView alloc] initWithTitle:@"This piece has been deleted"
                                    message:[NSString stringWithFormat:@"The piece \"%@\" was deleted in the server and it can not be edited",
                                             self.piece.shortText?:self.piece.longText?:@""]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil]
         show];
        [self cancel:nil];
        return;
    }
    
    self.piece.longText = self.pieceTextView.text;
    
//    // Extract the tags
//    NSMutableArray *substrings = [NSMutableArray array];
//    NSScanner *scanner = [NSScanner scannerWithString:self.piece.longText];
//    [scanner scanUpToString:@"#" intoString:nil]; // Scan all characters before #
//    while(![scanner isAtEnd]) {
//        NSString *substring = nil;
//        [scanner scanString:@"#" intoString:nil]; // Scan the # character
//        if([scanner scanUpToString:@" " intoString:&substring]) {
//            // If the space immediately followed the #, this will be skipped
//            [substrings addObject:substring];
//        }
//        [scanner scanUpToString:@"#" intoString:nil]; // Scan all characters before next #
//    }
//    self.piece.tags = [substrings componentsJoinedByString:@", "];
    
    self.piece.shortText = self.pieceCaptionView.text;
    
    self.piece.location = (GooglePlacesObject<GooglePlacesObject>*)self.addLocationButton.location;
    
    // Get the recording from audioRecorder
    NSURL *audioRecording = [self.audioRecorder getRecording];
    if (audioRecording) {
        Media *media = [Media newMediaForObject:self.piece];
        media.mediaType = @"audio";
        media.localURL = [audioRecording absoluteString];
    }

    // Delete any media that were indicated to be deleted
    for (Media *media in mediaToDelete) {
        // If its a local image, don't delete it
        if ([media.remoteURL length]) {
            [media deleteWitSuccess:nil
                            failure:^(NSError *error) {
                                NSLog(@"Error %@ deleting %@ when editing piece %@", error.localizedDescription, media.mediaTypeName, self.piece.shortText.length ? self.piece.shortText : @"");
            }];
        }
        [media remove];
    }
    
    self.piece = (Piece *)[self.piece cloneIntoNSManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];
    
    // Refresh the story with the updated piece relationship in main context
    // This is because refresh object does not refresh the relationships (only attributes)
    [self.piece.story cloneIntoNSManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];
    
    if (self.editMode == ModifyPieceViewControllerEditModeAddPiece)
    {
        [Piece createNewPiece:self.piece];
        NSUInteger currentPieceNum = [self.piece.story.pieces indexOfObject:self.piece];
        if (currentPieceNum == NSNotFound)
            currentPieceNum = self.piece.story.pieces.count;
        self.piece.story.currentPieceNum = currentPieceNum+1;

        NSLog(@"New piece %@ saved", self.piece);
        [TestFlight passCheckpoint:@"New piece created successfully"];
    }
    else if (self.editMode == ModifyPieceViewControllerEditModeEditPiece)
    {
        // If the piece's story has changed, update the old one and the new one
        [Piece editPiece:self.piece];
    }
    else {
        NSAssert(false, @"ModifyPieceViewController_No valid edit mode");
    }
    
    [self dismissEditViewWithCompletionBlock:^{
        if (self.delegate)
            [self.delegate modifyPieceViewController:self didFinishAddingPiece:self.piece];
    }];
}

- (IBAction)deleteAudioAlert:(UIButton *)sender
{
    UIAlertView *alertView = nil;
    alertView = [[UIAlertView alloc] initWithTitle:@"Delete Audio"
                                           message:@"Do you want to delete this audio piece?"
                                          delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    
    [alertView show];
}

- (IBAction)storyChangeButtonPressed:(id)sender
{
    NSLog(@"Current story is %@", self.piece.story.title);
    StoryPickerViewController *vc = [[StoryPickerViewController alloc] init];
    vc.delegate = self;
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nvc animated:YES completion:nil];
}

- (void) updateStoryTitle
{
    if (!self.piece.story.title)
        return;
        
    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:self.piece.story.title
                                                                      attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                                                   NSForegroundColorAttributeName: BANYAN_WHITE_COLOR}];
    NSAttributedString *changeStoryString = [[NSAttributedString alloc] initWithString:@"\rTap to change the story"
                                                                            attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:10],
                                                                                         NSForegroundColorAttributeName: BANYAN_WHITE_COLOR}];
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithAttributedString:titleString];
    [attrString appendAttributedString:changeStoryString];
    [self.storyTitleButton setAttributedTitle:attrString forState:UIControlStateNormal];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Delete Audio"] && buttonIndex==1) {
        Media *audioMedia = [Media getMediaOfType:@"audio" inMediaSet:self.piece.media];
        [mediaToDelete addObject:audioMedia];
        // Remove the delete button
        [[[self.audioPickerView subviews] lastObject] removeFromSuperview];
        self.doneButton.enabled = YES;
        return;
    }
}

# pragma mark StoryPickerViewControllerDelegate
- (void) storyPickerViewControllerDidPickStory:(Story *)story
{
    // A new story was picked.
    // Change the story of this piece to the new story
    self.piece.story = (Story *)[story cloneIntoNSManagedObjectContext:self.scratchMOC];
    self.storyID = story.objectID;
    [self updateStoryTitle];
}

# pragma mark - Keyboard notifications
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    kbSize.height += CGRectGetHeight(self.textViewInputAccessoryView.frame);
    UIEdgeInsets contentInsets = self.scrollView.contentInset;
    contentInsets.bottom = kbSize.height;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}

// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardDidHide:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = self.scrollView.contentInset;
    contentInsets.bottom = 0;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    [self.scrollView setContentOffset:CGPointMake(0, -contentInsets.top) animated:YES];
    kbSize = CGSizeZero;
}


- (IBAction)dismissKeyboard:(id)sender
{
    self.doneButton.enabled = [self checkForChanges];
    
    if (self.pieceTextView.isFirstResponder)
        [self.pieceTextView resignFirstResponder];
    
    if (self.pieceCaptionView.isFirstResponder)
        [self.pieceCaptionView resignFirstResponder];
}

- (BOOL)checkForChanges
{
    // TODO check with backup and return appropriately
    return YES;
}

- (IBAction)addHashTag:(id)sender
{
    self.pieceTextView.text=[NSString stringWithFormat:@"%@%@", self.pieceTextView.text, @"#"];
}

#pragma mark UITextFieldDelegate / UITextViewDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.pieceCaptionView) {
        [UIView animateWithDuration:0.5 animations:^{
            textField.backgroundColor = BANYAN_WHITE_COLOR;
        }];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.doneButton.enabled = [self checkForChanges];
    if (textField == self.pieceCaptionView) {
        [UIView animateWithDuration:0.5 animations:^{
            textField.backgroundColor = [BANYAN_WHITE_COLOR colorWithAlphaComponent:SUBVIEW_OPACITY];
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    textView.scrollEnabled = YES;

    if (textView == self.pieceTextView) {
        [UIView animateWithDuration:0.5 animations:^{
            CGRect frame = self.scrollView.bounds;
            frame.origin.y = self.scrollView.contentInset.top;
            frame.size.height = CGRectGetHeight([UIScreen mainScreen].applicationFrame) - kbSize.height;
            textView.frame = frame;
            [textView.layer setCornerRadius:0];
            textView.backgroundColor = BANYAN_WHITE_COLOR;
            
            // Remove the other subviews
            self.storyTitleButton.alpha = 0;
            self.pieceCaptionView.alpha = 0;
            self.addPhotoButton.alpha = 0;
            self.audioPickerView.alpha = 0;
            self.addLocationButton.alpha = 0;
        } completion:^(BOOL finished) {
            [self.storyTitleButton removeFromSuperview];
            [self.pieceCaptionView removeFromSuperview];
            [self.addPhotoButton removeFromSuperview];
            [self.audioPickerView removeFromSuperview];
            [self.addLocationButton removeFromSuperview];
            self.scrollView.scrollEnabled = NO;
            [textView setNeedsDisplay];
        }];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self.scrollView addSubview:self.storyTitleButton];
    [self.scrollView addSubview:self.pieceCaptionView];
    [self.scrollView addSubview:self.addPhotoButton];
    [self.scrollView addSubview:self.audioPickerView];
    [self.scrollView addSubview:self.addLocationButton];
    textView.scrollEnabled = NO;

    if (textView == self.pieceTextView) {
        [UIView animateWithDuration:0.5 animations:^{
            CGRect frame = self.scrollView.bounds;
            frame.origin.x = VIEW_INSETS;
            frame.origin.y = CGRectGetMaxY(self.pieceCaptionView.frame) + VIEW_INSETS;
            frame.size.width -= 2*VIEW_INSETS;
            frame.size.height = 88.0f;
            textView.frame = frame;
            [textView.layer setCornerRadius:8];
            self.pieceTextView.backgroundColor = [BANYAN_WHITE_COLOR colorWithAlphaComponent:SUBVIEW_OPACITY];
            
            self.storyTitleButton.alpha = 1;
            self.pieceCaptionView.alpha = 1;
            self.addPhotoButton.alpha = 1;
            self.audioPickerView.alpha = 1;
            self.addLocationButton.alpha = 1;
            self.scrollView.alpha = 1;
            
        } completion:^(BOOL finished) {
            self.scrollView.scrollEnabled = YES;
            [textView setNeedsDisplay];
        }];
    }
    self.doneButton.enabled = [self checkForChanges];
}

#pragma mark Methods to interface between views
- (void) dismissEditViewWithCompletionBlock:(void (^)(void))completionBlock
{
    [self dismissViewControllerAnimated:YES completion:completionBlock];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
    NSLog(@"Received memory warning in ModifyPieceViewController");
}

#undef TEXT_INSETS
#undef VIEW_INSETS
#undef CORNER_RADIUS
#undef SUBVIEW_OPACITY
@end

@implementation ModifyPieceViewController (AVCamViewControllerDelegate)

- (void) dismissAVCamViewController:(AVCamViewController *)viewController
{
    // Get all the subviews back
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.storyTitleButton];
    [self.scrollView addSubview:self.pieceCaptionView];
    [self.scrollView addSubview:self.pieceTextView];
    [self.scrollView addSubview:self.addPhotoButton];
    [self.scrollView addSubview:self.audioPickerView];
    [self.scrollView addSubview:self.addLocationButton];
    [UIView animateWithDuration:1
                     animations:^{
                         self.storyTitleButton.alpha = 1;
                         self.pieceCaptionView.alpha = 1;
                         self.pieceTextView.alpha = 1;
                         self.addPhotoButton.alpha = 1;
                         self.audioPickerView.alpha = 1;
                         self.addLocationButton.alpha = 1;
                         self.scrollView.alpha = 1;
                         [viewController hideAVCamViewControllerControls];
                     }
                     completion:^(BOOL finished){
                     }
     ];
}

- (void) avCamViewController:(AVCamViewController *)viewController finishedCapturingMediaWithInfo:(NSDictionary *)infoDict
{
    [self dismissAVCamViewController:viewController];
    // Add the current media to mediaToDelete
    [mediaToDelete addObjectsFromArray:[self.piece.media array]];
    Media *media = [Media newMediaForObject:self.piece];
    media.mediaType = @"image";
    media.localURL = [(NSURL *)[infoDict objectForKey:AVCamCaptureManagerInfoURL] absoluteString];
    UIImage *image = [infoDict objectForKey:AVCamCaptureManagerInfoImage];
    [self.addPhotoButton setImage:image];
    image = [image thumbnailImage:MEDIA_THUMBNAIL_SIZE transparentBorder:0 cornerRadius:2 interpolationQuality:kCGInterpolationHigh];
    media.thumbnail = image;
    [self.addPhotoButton setThumbnail:image forMedia:media];
    self.doneButton.enabled = [self checkForChanges];
}

@end

@implementation ModifyPieceViewController (MediaPickerViewControllerDelegate)
- (void) mediaPicker:(MediaPickerViewController *)mediaPicker finishedPickingMediaWithInfo:(NSDictionary *)info
{
    // Add the current media to mediaToDelete
    [mediaToDelete addObjectsFromArray:[self.piece.media array]];
    
    Media *media = [Media newMediaForObject:self.piece];
    media.mediaType = @"image";
    media.localURL = [(NSURL *)[info objectForKey:MediaPickerViewControllerInfoURL] absoluteString];
    UIImage *image = [info objectForKey:MediaPickerViewControllerInfoImage];
    [self.addPhotoButton setImage:image];
    image = [image thumbnailImage:MEDIA_THUMBNAIL_SIZE transparentBorder:0 cornerRadius:2 interpolationQuality:kCGInterpolationHigh];
    media.thumbnail = image;
    [self.addPhotoButton setThumbnail:image forMedia:media];
    self.doneButton.enabled = [self checkForChanges];
}

- (void) mediaPickerDidCancel:(MediaPickerViewController *)mediaPicker
{
    
}
@end

@implementation ModifyPieceViewController (AddPhotoButtonActions)

- (IBAction)addPhotoButtonTappedForCamera:(id)sender
{
    [self dismissKeyboard:nil];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:1
                     animations:^{
                         self.storyTitleButton.alpha = 0;
                         self.pieceCaptionView.alpha = 0;
                         self.pieceTextView.alpha = 0;
                         self.addPhotoButton.alpha = 0;
                         self.audioPickerView.alpha = 0;
                         self.addLocationButton.alpha = 0;
                         self.scrollView.alpha = 0;
                         [self.camViewController showAVCamViewControllerControls];
                     }
                     completion:^(BOOL finished){
                         [self.storyTitleButton removeFromSuperview];
                         [self.pieceCaptionView removeFromSuperview];
                         [self.pieceTextView removeFromSuperview];
                         [self.addPhotoButton removeFromSuperview];
                         [self.audioPickerView removeFromSuperview];
                         [self.addLocationButton removeFromSuperview];
                         [self.scrollView removeFromSuperview];
                     }
     ];
}

- (IBAction)addPhotoButtonTappedForGallery:(id)sender
{
    [self dismissKeyboard:nil];
    MediaPickerViewController *mediaPicker = [[MediaPickerViewController alloc] init];
    mediaPicker.delegate = self;
    [self addChildViewController:mediaPicker];
    [mediaPicker shouldStartPhotoLibraryPickerController];
}

- (IBAction)addPhotoButtonTappedToDeleteImage:(id)sender
{
    Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.piece.media];
    [mediaToDelete addObject:imageMedia];
    [self.addPhotoButton unsetImage];
}

@end

@implementation ModifyPieceViewController (LocationPickerButtonDelegate)

- (void)locationPickerButtonTapped:(LocationPickerButton *)sender
{
    [self.addLocationButton locationPickerLocationEnabled:YES];
    // Create the navigation controller and present it.
    GooglePlacePickerViewController *gppVC = [[GooglePlacePickerViewController alloc] initWithNibName:@"GooglePlacePickerViewController" bundle:nil];
    gppVC.delegate = self;
    [self presentViewController:gppVC animated:YES completion:nil];
}

- (void)locationPickerButtonToggleLocationEnable:(LocationPickerButton *)sender
{
    BOOL isLocationEnabled = sender.getEnabledState;
    isLocationEnabled = !isLocationEnabled;
    [self.addLocationButton locationPickerLocationEnabled:isLocationEnabled];
    if (isLocationEnabled) {
        [self locationPickerButtonTapped:sender];
    }
}

@end

@implementation ModifyPieceViewController (GooglePlacesViewControllerDelegate)
- (void)googlePlacesViewControllerPickedLocation:(BNDuckTypedObject<GooglePlacesObject>*)place
{
    self.addLocationButton.location = place;
}

@end
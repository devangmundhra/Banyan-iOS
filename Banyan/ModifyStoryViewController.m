//
//  ModifyStoryViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModifyStoryViewController.h"
#import "Story_Defines.h"
#import "BanyanAppDelegate.h"
#import "SVSegmentedControl.h"
#import "UIImage+Create.h"
#import "Story+Create.h"
#import "LocationPickerButton.h"
#import "User.h"
#import <QuartzCore/QuartzCore.h>
#import "SSTextField.h"
#import "Media.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "BNMisc.h"
#import "Story+Permissions.h"

@interface ModifyStoryViewController ()
{
    NSInteger contributors;
    NSInteger viewers;
}

@property (weak, nonatomic) NSString *storyTitle;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet SSTextField *storyTitleTextField;
@property (strong, nonatomic) IBOutlet SVSegmentedControl *contributorPrivacySegmentedControl;
@property (strong, nonatomic) IBOutlet SVSegmentedControl *viewerPrivacySegmentedControl;

@property (weak, nonatomic) IBOutlet UIButton *inviteContactsButton;
@property (weak, nonatomic) IBOutlet LocationPickerButton *addLocationButton;
@property (weak, nonatomic) IBOutlet SingleImagePickerButton *addPhotoButton;

@property (weak, nonatomic) UITextField *activeField;
@property (nonatomic) CGSize kbSize;

@property (weak, nonatomic) IBOutlet UILabel *numSpectatorsLabel;
@property (strong, nonatomic) NSMutableArray *invitedToViewList;

@property (weak, nonatomic) IBOutlet UILabel *numPlayersLabel;
@property (strong, nonatomic) NSMutableArray *invitedToContributeList;

@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

@property (nonatomic) BOOL isLocationEnabled;
@property (strong, nonatomic) BNFBLocationManager *locationManager;

@property (nonatomic) ModifyStoryViewControllerEditMode editMode;
@property (strong, nonatomic) Story *backupStory_;

@property (strong, nonatomic) NSMutableSet *mediaToDelete;
@property (strong, nonatomic) NSOrderedSet *backupMedia_;

@end

@implementation ModifyStoryViewController

// Timeout for finding location
#define kFindLocationTimeOut 0.5*60 // half a minute
#define kTokenisingCharacter @","

@synthesize scrollView = _scrollView;
@synthesize storyTitle = _storyTitle;
@synthesize storyTitleTextField = _storyTitleTextField;
@synthesize tapRecognizer = _tapRecognizer;
@synthesize invitedToViewList = _invitedToViewList;
@synthesize invitedToContributeList = _invitedToContributeList;
@synthesize locationManager = _locationManager;
@synthesize activeField = _activeField;
@synthesize contributorPrivacySegmentedControl = _contributorPrivacySegmentedControl;
@synthesize viewerPrivacySegmentedControl = _viewerPrivacySegmentedControl;
@synthesize addLocationButton = _addLocationButton;
@synthesize addPhotoButton = _addPhotoButton;
@synthesize numPlayersLabel, numSpectatorsLabel;
@synthesize backupStory_ = _backupStory_;
@synthesize editMode = _editMode;
@synthesize delegate = _delegate;
@synthesize backupMedia_ = _backupMedia_;
@synthesize mediaToDelete;

- (id) initWithStory:(Story *)story
{
    if (self = [super initWithNibName:@"ModifyStoryViewController" bundle:nil]) {
        self.hidesBottomBarWhenPushed = YES;
        self.story = story;
        if (self.story.remoteStatus == RemoteObjectStatusLocal) {
            self.editMode = ModifyStoryViewControllerEditModeAdd;
        } else {
            self.editMode = ModifyStoryViewControllerEditModeEdit;
            self.backupStory_ = [NSEntityDescription insertNewObjectForEntityForName:[[story entity] name] inManagedObjectContext:[story managedObjectContext]];
            self.backupMedia_ = [NSOrderedSet orderedSetWithOrderedSet:self.story.media];
            [self.backupStory_ cloneFrom:story];
        }
        
    }
    return self;
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
	// Do any additional setup after loading the view, typically from a nib.
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)]];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];
    self.addPhotoButton.delegate = self;
    
    mediaToDelete = [NSMutableSet set];
    
    self.inviteContactsButton.enabled = 1;
    [self.inviteContactsButton setBackgroundColor:BANYAN_GREEN_COLOR];
    [self.inviteContactsButton setImage:[UIImage imageNamed:@"addUserSymbol"] forState:UIControlStateNormal];
    
    self.storyTitleTextField.delegate = self;
    self.storyTitleTextField.textEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5);
    self.storyTitleTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    if (!self.locationManager) {
        self.locationManager = [[BNFBLocationManager alloc] initWithDelegate:self];
    }
    self.isLocationEnabled = self.story.isLocationEnabled;
    self.addLocationButton.delegate = self;
    [self.addLocationButton locationPickerLocationEnabled:self.isLocationEnabled];
    if (self.isLocationEnabled) {
        self.locationManager.location = self.story.location;
        if ([self.story.location.name length]) {
            [self.addLocationButton setLocationPickerTitle:self.story.location.name];
        }
    }
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    
    self.contributorPrivacySegmentedControl = [[SVSegmentedControl alloc] initWithSectionTitles:@[@"Everyone", @"Selected"]];
    [self.contributorPrivacySegmentedControl addTarget:self action:@selector(storyPrivacySegmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    self.viewerPrivacySegmentedControl = [[SVSegmentedControl alloc] initWithSectionTitles:@[@"Everyone", @"Limited", @"Selected"]];
    [self.viewerPrivacySegmentedControl addTarget:self action:@selector(storyPrivacySegmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    self.contributorPrivacySegmentedControl.crossFadeLabelsOnDrag = YES;
    self.contributorPrivacySegmentedControl.font = [UIFont fontWithName:STORY_FONT size:12];;
    self.contributorPrivacySegmentedControl.thumb.tintColor = BANYAN_GREEN_COLOR;
    self.contributorPrivacySegmentedControl.textColor = BANYAN_WHITE_COLOR;
    self.contributorPrivacySegmentedControl.height = 25;
    [self.scrollView addSubview:self.contributorPrivacySegmentedControl];
    self.contributorPrivacySegmentedControl.center = CGPointMake(141, 96);
    
    
    self.viewerPrivacySegmentedControl.crossFadeLabelsOnDrag = YES;
    self.viewerPrivacySegmentedControl.font = [UIFont fontWithName:STORY_FONT size:12];
    self.viewerPrivacySegmentedControl.thumb.tintColor = BANYAN_GREEN_COLOR;
    self.viewerPrivacySegmentedControl.backgroundTintColor = BANYAN_BROWN_COLOR;
    self.viewerPrivacySegmentedControl.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 3);
    self.viewerPrivacySegmentedControl.textColor = BANYAN_WHITE_COLOR;
    self.viewerPrivacySegmentedControl.height = 25;
    [self.scrollView addSubview:self.viewerPrivacySegmentedControl];
    self.viewerPrivacySegmentedControl.center = CGPointMake(141, 151);
    
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.invitedToContributeList = [NSMutableArray array];
    self.invitedToViewList = [NSMutableArray array];
    
    if (self.editMode == ModifyStoryViewControllerEditModeEdit) {
        // Set the title and permissions
        self.storyTitleTextField.text = self.story.title;
        // Players
        if ([[self.story contributorPrivacyScope] isEqualToString:kBNStoryPrivacyScopeInvited]) {
            [self.contributorPrivacySegmentedControl setSelectedSegmentIndex:ContributorPrivacySegmentedControlInvited animated:NO];
            numPlayersLabel.hidden = NO;
            numPlayersLabel.text = [NSString stringWithFormat:@"%u", [self.story numberOfContributors]];
            self.invitedToContributeList = [NSMutableArray arrayWithArray:[self.story storyContributors]];
        } else {
            [self.contributorPrivacySegmentedControl setSelectedSegmentIndex:ContributorPrivacySegmentedControlPublic animated:NO];
            numPlayersLabel.hidden = YES;
        }
        // Spectators
        if ([[self.story viewerPrivacyScope] isEqualToString:kBNStoryPrivacyScopeInvited]) {
            [self.viewerPrivacySegmentedControl setSelectedSegmentIndex:ViewerPrivacySegmentedControlInvited animated:NO];
            numSpectatorsLabel.hidden = NO;
            numSpectatorsLabel.text = [NSString stringWithFormat:@"%u", [self.story numberOfViewers]];
            self.invitedToViewList = [NSMutableArray arrayWithArray:[self.story storyViewers]];
        } else if ([[self.story viewerPrivacyScope] isEqualToString:kBNStoryPrivacyScopeLimited]) {
            [self.viewerPrivacySegmentedControl setSelectedSegmentIndex:ViewerPrivacySegmentedControlLimited animated:NO];
            numSpectatorsLabel.hidden = YES;
        } else {
            [self.viewerPrivacySegmentedControl setSelectedSegmentIndex:ViewerPrivacySegmentedControlPublic animated:NO];
            numSpectatorsLabel.hidden = YES;
        }
        
        // Cover image
        Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.story.media];
        
        if (imageMedia) {
            if ([imageMedia.remoteURL length]) {
                [self.addPhotoButton.imageView setImageWithURL:[NSURL URLWithString:imageMedia.remoteURL] placeholderImage:nil options:SDWebImageProgressiveDownload];
            } else if ([imageMedia.localURL length]) {
                ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
                [library assetForURL:[NSURL URLWithString:imageMedia.localURL] resultBlock:^(ALAsset *asset) {
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
                [self.addPhotoButton.imageView  setImageWithURL:nil];
            }
        }
        
        self.title = @"Edit Story";
    } else {
        [self.contributorPrivacySegmentedControl setSelectedSegmentIndex:ContributorPrivacySegmentedControlInvited animated:NO];
        numPlayersLabel.hidden = NO;
        [self.viewerPrivacySegmentedControl setSelectedSegmentIndex:ViewerPrivacySegmentedControlPublic animated:NO];
        numSpectatorsLabel.hidden = YES;
        self.title = @"Add Story";
    }
    
    [self updateScrollViewContentSize];
    
    [self.inviteContactsButton addTarget:self action:@selector(inviteContacts:) forControlEvents:UIControlEventTouchUpInside];
    self.inviteContactsButton.enabled = (self.contributorPrivacySegmentedControl.selectedSegmentIndex == ContributorPrivacySegmentedControlInvited) || (self.viewerPrivacySegmentedControl.selectedSegmentIndex == ViewerPrivacySegmentedControlInvited);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark- Target Actions for story
- (void) inviteContacts:(id)sender
{
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] initWithViewerPermissions:[self viewerPrivacyDictionary]
                                                                                                     contributorPermission:[self contributorPrivacyDictionary]];
    invitedTableViewController.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:invitedTableViewController] animated:YES completion:nil];
}

// Update the story
- (void)deleteBackupStory
{
    if (self.backupStory_) {
        [self.backupStory_ remove];
        self.backupStory_ = nil;
    }
}

- (void)restoreBackupStory:(BOOL)upload
{
    if (self.backupStory_) {
        [self.story cloneFrom:self.backupStory_];
        
        // Restore the media
        if (![self.backupMedia_ isEqualToOrderedSet:self.story.media]) {
            // Remove any new media that might have been added
            NSMutableOrderedSet *mediaToRemove = [NSMutableOrderedSet orderedSetWithOrderedSet:self.story.media];
            [mediaToRemove minusOrderedSet:self.backupMedia_];
            for (Media *media in mediaToRemove) {
                [media remove];
            }
            assert([self.story.media intersectsOrderedSet:self.backupMedia_] && [self.backupMedia_ intersectsOrderedSet:self.story.media]);
            // Set the old media back again in case the ordering was changed
            [self.story setMedia:self.backupMedia_];
        }
    }
}

- (IBAction)done:(UIBarButtonItem *)sender
{
    [self dismissKeyboard:nil];
    // Title
    self.story.title = (self.storyTitleTextField.text && ![self.storyTitleTextField.text isEqualToString:@""]) ? self.storyTitleTextField.text : [BNMisc longCurrentDate];
    
    // Story Privacy
    self.story.writeAccess = [self contributorPrivacyDictionary];
    self.story.readAccess = [self viewerPrivacyDictionary];
    
    // Story Location
    if (self.isLocationEnabled == YES) {
        self.story.isLocationEnabled = YES;
        self.story.location = (FBGraphObject<FBGraphPlace> *)self.locationManager.location;
    } else  {
        self.story.isLocationEnabled = NO;
    }
    
    // Delete any media that were indicated to be deleted
    for (Media *media in mediaToDelete) {
        // If its a local image, don't delete it
        if ([media.remoteURL length]) {
            [media deleteWitSuccess:nil
                            failure:^(NSError *error) {
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error deleting %@ when editing piece %@", media.mediaTypeName, self.story.title]
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
    
    // Upload Story
    if (self.editMode == ModifyStoryViewControllerEditModeAdd) {
        [Story createNewStory:self.story];
        
        NSLog(@"New story %@ saved", self.story);
        [TestFlight passCheckpoint:@"New Story created successfully"];
    } else if (self.editMode == ModifyStoryViewControllerEditModeEdit) {
        [Story editStory:self.story];
    } else {
        assert(false);
        NSLog(@"ModifyStoryViewController_No valid edit mode");
    }
    
    [self dismissEditViewWithCompletionBlock:^{
        [self.delegate modifyStoryViewControllerDidSelectStory:self.story];
    }];
}

- (IBAction)cancel:(id)sender
{
    if (self.editMode == ModifyStoryViewControllerEditModeEdit) {
        [self restoreBackupStory:NO];
    }
    
	//remove the original piece in case of local draft unsaved
	if (self.editMode == ModifyStoryViewControllerEditModeAdd)
		[self.story remove];
    
	self.story = nil; // Just in case
    [self dismissEditViewWithCompletionBlock:^{
        if ([self.delegate respondsToSelector:@selector(modifyStoryViewControllerDidDismiss:)]) {
            [self.delegate modifyStoryViewControllerDidDismiss:self];
        }
    }];
}

# pragma mark story privacy

- (void) storyPrivacySegmentedControlChangedValue:(SVSegmentedControl *)segmentedControl
{
    if (segmentedControl == self.contributorPrivacySegmentedControl) {
        if (segmentedControl.selectedSegmentIndex == ContributorPrivacySegmentedControlInvited) {
            self.viewerPrivacySegmentedControl.enabled = YES;
            self.viewerPrivacySegmentedControl.alpha = 1;
            numPlayersLabel.hidden = NO;
        } else {
            if (self.viewerPrivacySegmentedControl.selectedSegmentIndex != ViewerPrivacySegmentedControlPublic) {
                [self.viewerPrivacySegmentedControl setSelectedSegmentIndex:ViewerPrivacySegmentedControlPublic animated:YES];
            }
            self.viewerPrivacySegmentedControl.enabled = NO;
            self.viewerPrivacySegmentedControl.alpha = 0.5;
            numPlayersLabel.hidden = YES;
        }
    }
    
    numSpectatorsLabel.hidden = self.viewerPrivacySegmentedControl.selectedSegmentIndex != ViewerPrivacySegmentedControlInvited;
    self.inviteContactsButton.enabled = (self.contributorPrivacySegmentedControl.selectedSegmentIndex == ContributorPrivacySegmentedControlInvited) || (self.viewerPrivacySegmentedControl.selectedSegmentIndex == ViewerPrivacySegmentedControlInvited);
}

- (NSString *)contributorScope
{
    if (self.contributorPrivacySegmentedControl.selectedSegmentIndex == ContributorPrivacySegmentedControlInvited) {
        return kBNStoryPrivacyScopeInvited;
    } else {
        return kBNStoryPrivacyScopePublic;
    }
}

- (NSDictionary *)contributorsInvited
{
    NSDictionary *dictToReturn = [NSDictionary dictionaryWithObject:self.invitedToContributeList forKey:kBNStoryPrivacyInvitedFacebookFriends];
    return dictToReturn;
}

- (NSDictionary *)contributorPrivacyDictionary
{
    NSMutableDictionary *contributorsDictionary = [NSMutableDictionary dictionary];
    
    [contributorsDictionary setObject:[self contributorScope] forKey:kBNStoryPrivacyScope];
    [contributorsDictionary setObject:[self contributorsInvited] forKey:kBNStoryPrivacyInviteeList];
    return [contributorsDictionary copy];
}

- (NSString *)viewerScope
{
    switch (self.viewerPrivacySegmentedControl.selectedSegmentIndex) {
        case ViewerPrivacySegmentedControlInvited:
            return kBNStoryPrivacyScopeInvited;
            break;
            
        case ViewerPrivacySegmentedControlLimited:
            return kBNStoryPrivacyScopeLimited;
            break;
            
        case ViewerPrivacySegmentedControlPublic:
            return kBNStoryPrivacyScopePublic;
            break;
            
        default:
            return kBNStoryPrivacyScopeInvited;
            break;
    }
}

- (NSDictionary *)viewersInvited
{
    // Whose fb friends to call depends upon the list added in kBNStoryPrivacyInvitedFacebookFriends
    if ([[self viewerScope] isEqualToString:kBNStoryPrivacyScopeLimited]) {
        BNSharedUser *currentUser = [BNSharedUser currentUser];
        if (currentUser) {
            NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                            currentUser.name, @"name",
                                            currentUser.facebookId, @"id", nil];
            if (![self.invitedToViewList containsObject:selfInvitation])
                [self.invitedToViewList addObject:selfInvitation];
        } else {
            if (HAVE_ASSERTS)
                assert(false);
            return nil;
        }
    }
    
    return [NSDictionary dictionaryWithObject:self.invitedToViewList forKey:kBNStoryPrivacyInvitedFacebookFriends];
}

- (NSDictionary *)viewerPrivacyDictionary
{
    NSMutableDictionary *viewersDictionary = [NSMutableDictionary dictionary];
    
    [viewersDictionary setObject:[self viewerScope] forKey:kBNStoryPrivacyScope];
    [viewersDictionary setObject:[self viewersInvited] forKey:kBNStoryPrivacyInviteeList];
    return [viewersDictionary copy];
}

#pragma mark SingleImagePickerButton methods
- (void) singleImagePickerButtonTapped:(SingleImagePickerButton *)sender;
{
    [self dismissKeyboard:sender];
    
    Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.story.media];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Modify Photo"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:imageMedia ? @"Delete Photo" : nil
                                                    otherButtonTitles:nil];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        [actionSheet addButtonWithTitle:MediaPickerControllerSourceTypeCamera];
    [actionSheet addButtonWithTitle:MediaPickerControllerSourceTypePhotoLib];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
    //    [actionSheet showFromTabBar:self.tabBarController.tabBar];
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
        Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.story.media];
        [mediaToDelete addObject:imageMedia];
        [self.addPhotoButton.imageView setImageWithURL:nil];
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
    // Add the current media to mediaToDelete
    [mediaToDelete addObjectsFromArray:[self.story.media array]];
    
    Media *media = [Media newMediaForObject:self.story];
    media.mediaType = @"image";
    UIImage *image = [info objectForKey:MediaPickerViewControllerInfoImage];
    media.localURL = [(NSURL *)[info objectForKey:MediaPickerViewControllerInfoURL] absoluteString];
    
    [self.addPhotoButton.imageView  cancelImageRequestOperation];
    [NSThread detachNewThreadSelector:@selector(useImage:) toTarget:self withObject:image];
}

- (void)mediaPickerDidCancel:(MediaPickerViewController *)mediaPicker
{
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
    self.isLocationEnabled = !self.isLocationEnabled;
    [self.addLocationButton locationPickerLocationEnabled:self.isLocationEnabled];
    if (self.isLocationEnabled) {
        [self locationPickerButtonTapped:sender];
    } else {
        [self.locationManager stopUpdatingLocation:nil];
    }
}

# pragma mark BNLocationManagerDelegate
- (void) locationUpdated
{
    if (self.locationManager.location)
        self.isLocationEnabled = YES;
    
    [self.addLocationButton locationPickerLocationUpdatedWithLocation:self.locationManager.location];
}

# pragma mark - Keyboard notifications
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
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

// Called when the UIKeyboardWillShowotification is sent.
- (void)keyboardWillBeShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.kbSize = kbSize;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

// Called when the UIKeyboardWillBeHidden is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}

-(void)didTapAnywhere: (UITapGestureRecognizer*) recognizer
{
    [self dismissKeyboard:NULL];
}

- (IBAction)dismissKeyboard:(id)sender
{
    if (self.activeField.isFirstResponder)
        [self.activeField resignFirstResponder];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

# pragma mark InvitedTableViewControllerDelegate
- (void)invitedTableViewController:(InvitedTableViewController *)invitedTableViewController
        finishedInvitingForViewers:(NSArray *)selectedViewers
                      contributors:(NSArray *)selectedContributors
{
    if (selectedViewers) {
        [self.invitedToViewList setArray:selectedViewers];
    }
    if (selectedContributors) {
        [self.invitedToContributeList setArray:selectedContributors];
    }
    numSpectatorsLabel.text = [NSString stringWithFormat:@"%u", self.invitedToViewList.count];
    numPlayersLabel.text = [NSString stringWithFormat:@"%u", self.invitedToContributeList.count];
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

- (void) updateScrollViewContentSize
{
    CGSize screenSize = [UIScreen mainScreen].applicationFrame.size;
    self.scrollView.contentSize = CGSizeMake(screenSize.width,
                                             screenSize.height
                                             - self.navigationController.navigationBar.frame.size.height);
}

#pragma mark Methods to interface between views
- (void) dismissEditViewWithCompletionBlock:(void (^)(void))completionBlock
{
    [self deleteBackupStory];
    [self dismissViewControllerAnimated:YES completion:completionBlock];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end

//
//  NewStoryViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewStoryViewController.h"
#import "Story_Defines.h"
#import "BanyanAppDelegate.h"
#import "SVSegmentedControl.h"
#import "UIImage+Create.h"
#import "Story+Create.h"
#import "LocationPickerButton.h"
#import "User_Defines.h"
#import <QuartzCore/QuartzCore.h>
#import "SSTextField.h"
#import "Media.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "BNMisc.h"

@interface NewStoryViewController ()
{
    NSInteger contributors;
    NSInteger viewers;
}

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;


@property (weak, nonatomic) NSString *storyTitle;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet SSTextField *storyTitleTextField;
@property (strong, nonatomic) IBOutlet SVSegmentedControl *contributorPrivacySegmentedControl;
@property (strong, nonatomic) IBOutlet SVSegmentedControl *viewerPrivacySegmentedControl;

@property (weak, nonatomic) IBOutlet UIButton *inviteContactsButton;
@property (weak, nonatomic) IBOutlet LocationPickerButton *addLocationButton;
@property (weak, nonatomic) IBOutlet MediaPickerButton *addPhotoButton;
@property (weak, nonatomic) IBOutlet TITokenFieldView *tagsFieldView;

@property (weak, nonatomic) UITextField *activeField;

@property (strong, nonatomic) NSMutableArray *invitedToViewList;
@property (strong, nonatomic) NSMutableArray *invitedToContributeList;

@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

@property (strong, nonatomic) Story *story;

@property (nonatomic) BOOL isLocationEnabled;
@property (strong, nonatomic) BNFBLocationManager *locationManager;

@end

@implementation NewStoryViewController

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.hidesBottomBarWhenPushed = YES;
        
        self.title = @"Create New Story";
        self.contributorPrivacySegmentedControl = [[SVSegmentedControl alloc] initWithSectionTitles:@[@"Everyone", @"Selected"]];
        [self.contributorPrivacySegmentedControl addTarget:self action:@selector(storyPrivacySegmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
        
        self.viewerPrivacySegmentedControl = [[SVSegmentedControl alloc] initWithSectionTitles:@[@"Everyone", @"Limited", @"Selected"]];
        [self.viewerPrivacySegmentedControl addTarget:self action:@selector(storyPrivacySegmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self registerForKeyboardNotifications];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self unregisterForKeyboardNotifications];
}

/*
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![BanyanAppDelegate loggedIn]) {
        [self.view setUserInteractionEnabled:NO];
        CALayer *layer = [self.view layer];
        [layer setRasterizationScale:0.3];
        [layer setShouldRasterize:YES];
        layer.opacity = 0.3;
        [self.navigationItem setRightBarButtonItem:nil];
    } else {
        [self.view setUserInteractionEnabled:YES];
        CALayer *layer = [self.view layer];
        [layer setRasterizationScale:1.0];
        [layer setShouldRasterize:NO];
        layer.opacity = 1;
    }
}
 */

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.addPhotoButton.hidden = YES; // Stories don't have photos
    
    self.story = [Story newDraftStory];

    self.inviteContactsButton.enabled = 1;
    [self.inviteContactsButton setBackgroundColor:BANYAN_GREEN_COLOR];
    [self.inviteContactsButton setImage:[UIImage imageNamed:@"addUserSymbol"] forState:UIControlStateNormal];
    
    self.storyTitleTextField.delegate = self;
    self.storyTitleTextField.textEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5);
    self.storyTitleTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    if (!self.locationManager) {
        self.locationManager = [[BNFBLocationManager alloc] initWithDelegate:self];
    }
    self.isLocationEnabled = NO;
    self.addLocationButton.delegate = self;
    [self.addLocationButton locationPickerLocationEnabled:self.isLocationEnabled];
    if (self.isLocationEnabled)
        [self.locationManager beginUpdatingLocation];
    
    self.addPhotoButton.delegate = self;
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    self.invitedToContributeList = [NSMutableArray array];
    self.invitedToViewList = [NSMutableArray array];
    
    CGRect aRect = self.contributorPrivacySegmentedControl.thumb.frame;
    [self.contributorPrivacySegmentedControl setSelectedSegmentIndex:ContributorPrivacySegmentedControlInvited animated:NO];
    self.contributorPrivacySegmentedControl.crossFadeLabelsOnDrag = YES;
    self.contributorPrivacySegmentedControl.height = 25;
    self.contributorPrivacySegmentedControl.font = [UIFont fontWithName:STORY_FONT size:12];;
    self.contributorPrivacySegmentedControl.thumb.tintColor = BANYAN_GREEN_COLOR;
    self.contributorPrivacySegmentedControl.textColor = BANYAN_WHITE_COLOR;
    self.contributorPrivacySegmentedControl.sectionImages = [NSArray arrayWithObjects:[UIImage imageWithColor:BANYAN_WHITE_COLOR forRect:aRect],
                                                             [UIImage imageWithColor:BANYAN_BROWN_COLOR forRect:aRect], nil];
    [self.scrollView addSubview:self.contributorPrivacySegmentedControl];
    self.contributorPrivacySegmentedControl.center = CGPointMake(160, 78);

    [self.viewerPrivacySegmentedControl setSelectedSegmentIndex:ViewerPrivacySegmentedControlPublic animated:NO];
    self.viewerPrivacySegmentedControl.crossFadeLabelsOnDrag = YES;
    self.viewerPrivacySegmentedControl.height = 25;
    self.viewerPrivacySegmentedControl.font = [UIFont fontWithName:STORY_FONT size:12];
    self.viewerPrivacySegmentedControl.thumb.tintColor = BANYAN_GREEN_COLOR;
    self.viewerPrivacySegmentedControl.backgroundTintColor = BANYAN_BROWN_COLOR;
    self.viewerPrivacySegmentedControl.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 3);
    self.viewerPrivacySegmentedControl.textColor = BANYAN_WHITE_COLOR;
    [self.scrollView addSubview:self.viewerPrivacySegmentedControl];
    self.viewerPrivacySegmentedControl.center = CGPointMake(160, 132);
    
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Tags
    self.tagsFieldView.scrollEnabled = NO;
    [self.tagsFieldView.tokenField setDelegate:self];
	[self.tagsFieldView.tokenField addTarget:self action:@selector(tokenFieldFrameDidChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
	[self.tagsFieldView.tokenField setTokenizingCharacters:[NSCharacterSet characterSetWithCharactersInString:@",;."]]; // Default is a comma
    [self.tagsFieldView.tokenField addTarget:self action:@selector(tokenFieldChangedEditing:) forControlEvents:UIControlEventEditingDidBegin];
	[self.tagsFieldView.tokenField addTarget:self action:@selector(tokenFieldChangedEditing:) forControlEvents:UIControlEventEditingDidEnd];
    self.tagsFieldView.tokenField.returnKeyType = UIReturnKeyDone;
    if (self.story.tags) {
        [[self.story.tags componentsSeparatedByString:kTokenisingCharacter]
         enumerateObjectsUsingBlock:^(NSString *token, NSUInteger idx, BOOL *stop) {
            [self.tagsFieldView.tokenField addTokenWithTitle:token];
        }];
    }
    else {
        [self.tagsFieldView.tokenField setPromptText:@"Tags: "];
    }
    
    [self updateScrollViewContentSize];

    [self.inviteContactsButton addTarget:self action:@selector(inviteContacts:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidUnload
{
    [self setStoryTitle:nil];
    [self setStoryTitleTextField:nil];
    [self setTapRecognizer:nil];
    [self setInvitedToViewList:nil];
    [self setInvitedToContributeList:nil];
    [self setLocationManager:nil];
    [self setTagsFieldView:nil];
    [self setAddLocationButton:nil];
    [self setAddPhotoButton:nil];
    [self setScrollView:nil];
    [self setContributorPrivacySegmentedControl:nil];
    [self setViewerPrivacySegmentedControl:nil];
    [self setInviteContactsButton:nil];
    [self setDoneButton:nil];
    [self setCancelButton:nil];
    [self setNavigationBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark- Target Actions for new story
- (void) inviteContacts:(id)sender
{
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] initWithViewerPermissions:[self viewerPrivacyDictionary]
                                                                                                     contributorPermission:[self contributorPrivacyDictionary]];
    invitedTableViewController.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:invitedTableViewController] animated:YES completion:nil];
}

// Save the new story added
- (IBAction)doneNewStory:(UIBarButtonItem *)sender 
{
    [self dismissKeyboard:nil];
    // Title
    self.story.title = ![self.storyTitleTextField.text isEqualToString:@""] ? self.storyTitleTextField.text : [BNMisc longCurrentDate];
    
    // Story Privacy    
    self.story.writeAccess = [self contributorPrivacyDictionary];
    self.story.readAccess = [self viewerPrivacyDictionary];
    
    // Story Location
    if (self.isLocationEnabled == YES) {
        self.story.isLocationEnabled = [NSNumber numberWithBool:YES];
        self.story.location = (FBGraphObject<FBGraphPlace> *)self.locationManager.location;
    } else  {
        self.story.isLocationEnabled = [NSNumber numberWithBool:NO];
    }
    
    NSArray *tagsArray = [self.tagsFieldView tokenTitles];
    NSString *tags = [tagsArray componentsJoinedByString:kTokenisingCharacter];
    self.story.tags = tags;
    NSLog(@"tags are %@", tags);
    
    // Upload Story
    [Story createNewStory:self.story];

    NSLog(@"New story %@ saved", self.story);
    [TestFlight passCheckpoint:@"New Story created successfully"];
    
    [self dismissEditView];
}

- (IBAction)cancel:(id)sender
{
    [self dismissEditView];
}

# pragma mark story privacy

- (void) storyPrivacySegmentedControlChangedValue:(SVSegmentedControl *)segmentedControl
{
    if (segmentedControl == self.contributorPrivacySegmentedControl) {
        if (segmentedControl.selectedSegmentIndex == ContributorPrivacySegmentedControlInvited){
            self.viewerPrivacySegmentedControl.enabled = YES;
            self.viewerPrivacySegmentedControl.alpha = 1;
        } else {
            if (self.viewerPrivacySegmentedControl.selectedSegmentIndex != ViewerPrivacySegmentedControlPublic) {
                [self.viewerPrivacySegmentedControl setSelectedSegmentIndex:ViewerPrivacySegmentedControlPublic animated:YES];
            }
            self.viewerPrivacySegmentedControl.enabled = NO;
            self.viewerPrivacySegmentedControl.alpha = 0.5;
        }
    }
    
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
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [currentUser objectForKey:USER_NAME], @"name",
                                        [currentUser objectForKey:USER_FACEBOOK_ID], @"id", nil];
        [self.invitedToContributeList addObject:selfInvitation];
    } else {
        if (HAVE_ASSERTS)
            assert(false);
        return nil;
    }
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
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [currentUser objectForKey:USER_NAME], @"name",
                                        [currentUser objectForKey:USER_FACEBOOK_ID], @"id", nil];
        [self.invitedToViewList addObject:selfInvitation];
    } else {
        if (HAVE_ASSERTS)
            assert(false);
        return nil;
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

#pragma mark MediaPickerButtonDelegate methods
- (void) mediaPickerButtonTapped:(MediaPickerButton *)sender
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
        // If its a local image, don't delete it
        if ([imageMedia.localURL length])
            imageMedia.localURL = nil;
        if ([imageMedia.remoteURL length]) {
            [imageMedia deleteWitSuccess:nil failure:nil];
        }
        [imageMedia remove];
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
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    // If active text field is hidden by keyboard, scroll it so it's visible    
    if (self.activeField == self.tagsFieldView.tokenField) {
        CGPoint scrollPoint = CGPointMake(0, self.tagsFieldView.frame.origin.y + self.tagsFieldView.separator.frame.origin.y - self.navigationBar.frame.size.height);
        [self.scrollView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillBeHidden is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}

-(void)didTapAnywhere: (UITapGestureRecognizer*) recognizer {    
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
    if (selectedViewers)
        [self.invitedToViewList setArray:selectedViewers];
    if (selectedContributors) {
        [self.invitedToViewList addObjectsFromArray:selectedContributors];
        [self.invitedToContributeList setArray:selectedContributors];
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

#pragma mark TITokenField Delegate
- (BOOL)tokenField:(TITokenField *)tokenField willRemoveToken:(TIToken *)token {
	return YES;
}

- (void)tokenFieldChangedEditing:(TITokenField *)tokenField {
	// There's some kind of annoying bug where UITextFieldViewModeWhile/UnlessEditing doesn't do anything.
	[tokenField setRightViewMode:(tokenField.editing ? UITextFieldViewModeAlways : UITextFieldViewModeNever)];
}

- (void)tokenFieldFrameDidChange:(TITokenField *)tokenField
{    
    if (self.activeField == self.tagsFieldView.tokenField) {
        CGPoint scrollPoint = CGPointMake(0, self.tagsFieldView.frame.origin.y + self.tagsFieldView.separator.frame.origin.y - self.navigationController.navigationBar.frame.size.height);
        [self.scrollView setContentOffset:scrollPoint animated:YES];
    }}

- (void) updateScrollViewContentSize
{
    CGSize screenSize = [UIScreen mainScreen].applicationFrame.size;
    self.scrollView.contentSize = CGSizeMake(screenSize.width,
                                             screenSize.height
                                             - self.navigationController.navigationBar.frame.size.height);
//                                             + self.tagsFieldView.separator.frame.origin.y);
}

#pragma mark Methods to interface between views
- (void) dismissEditView
{
//    [self deleteBackupStory];
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

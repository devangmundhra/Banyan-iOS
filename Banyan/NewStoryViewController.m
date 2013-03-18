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
#import "User+Edit.h"
#import "SVSegmentedControl.h"
#import "UIImage+Create.h"

@interface NewStoryViewController ()
{
    NSInteger contributors;
    NSInteger viewers;
}

@property (weak, nonatomic) NSString *storyTitle;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *storyTitleTextField;
@property (strong, nonatomic) IBOutlet SVSegmentedControl *contributorPrivacySegmentedControl;
@property (strong, nonatomic) IBOutlet SVSegmentedControl *viewerPrivacySegmentedControl;
@property (weak, nonatomic) IBOutlet UIButton *inviteContributorsButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteViewersButton;
@property (weak, nonatomic) IBOutlet UIButton *addLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (weak, nonatomic) IBOutlet TITokenFieldView *tagsFieldView;

@property (weak, nonatomic) UITextField *activeField;

@property (strong, nonatomic) NSMutableArray *invitedToViewList;
@property (strong, nonatomic) NSMutableArray *invitedToContributeList;

@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

@property (strong, nonatomic) Story *story;

@property (nonatomic) BOOL keyboardIsShown;

@property (nonatomic) BOOL isLocationEnabled;
@property (strong, nonatomic) BNLocationManager *locationManager;
@end

@implementation NewStoryViewController

// These correspond to the index for UISegmentedControl for Write
typedef enum {
    ContributorPrivacySegmentedControlPublic = 0,
    ContributorPrivacySegmentedControlInvited = 1,
} StoryPrivacySegmentIndex;

// These correspond to the index for UISegmentedControl for Read
typedef enum {
    ViewerPrivacySegmentedControlPublic = 0,
    ViewerPrivacySegmentedControlLimited = 1,
    ViewerPrivacySegmentedControlInvited = 2,
} ViewerPrivacySegmentedControl;

// Timeout for finding location
#define kFindLocationTimeOut 0.5*60 // half a minute

@synthesize scrollView = _scrollView;
@synthesize storyTitle = _storyTitle;
@synthesize storyTitleTextField = _storyTitleTextField;
@synthesize delegate = _delegate;
@synthesize keyboardIsShown = _keyboardIsShown;
@synthesize tapRecognizer = _tapRecognizer;
@synthesize invitedToViewList = _invitedToViewList;
@synthesize invitedToContributeList = _invitedToContributeList;
@synthesize inviteContributorsButton = _inviteContributorsButton;
@synthesize inviteViewersButton = _inviteViewersButton;
@synthesize locationManager = _locationManager;
@synthesize activeField = _activeField;
@synthesize contributorPrivacySegmentedControl = _contributorPrivacySegmentedControl;
@synthesize viewerPrivacySegmentedControl = _viewerPrivacySegmentedControl;
@synthesize addLocationButton = _addLocationButton;
@synthesize addPhotoButton = _addPhotoButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(doneNewStory:)]];
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];
        
        self.contributorPrivacySegmentedControl = [[SVSegmentedControl alloc] initWithSectionTitles:@[@"Public", @"Private"]];
        [self.contributorPrivacySegmentedControl addTarget:self action:@selector(storyPrivacySegmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
        
        self.viewerPrivacySegmentedControl = [[SVSegmentedControl alloc] initWithSectionTitles:@[@"Public", @"Limited", @"Private"]];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.inviteContributorsButton.enabled = 1;
    
    self.storyTitleTextField.delegate = self;
//    [self.storyTitleTextField becomeFirstResponder];
    self.storyTitleTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    self.invitedToContributeList = [NSMutableArray array];
    self.invitedToViewList = [NSMutableArray array];
    self.story = [NSEntityDescription insertNewObjectForEntityForName:kBNStoryClassKey
                                               inManagedObjectContext:BANYAN_USER_CONTENT_MANAGED_OBJECT_CONTEXT];
    
    CGRect aRect = self.contributorPrivacySegmentedControl.thumb.frame;
    self.contributorPrivacySegmentedControl.selectedIndex = ContributorPrivacySegmentedControlInvited;
    self.contributorPrivacySegmentedControl.crossFadeLabelsOnDrag = YES;
    self.contributorPrivacySegmentedControl.height = 25;
    self.contributorPrivacySegmentedControl.font = [UIFont fontWithName:STORY_FONT size:12];;
    self.contributorPrivacySegmentedControl.thumb.tintColor = BANYAN_GREEN_COLOR;
    self.contributorPrivacySegmentedControl.textColor = BANYAN_WHITE_COLOR;
    self.contributorPrivacySegmentedControl.sectionImages = [NSArray arrayWithObjects:[UIImage imageWithColor:BANYAN_WHITE_COLOR forRect:aRect],
                                                             [UIImage imageWithColor:BANYAN_BROWN_COLOR forRect:aRect], nil];
    
    self.viewerPrivacySegmentedControl.selectedIndex = ViewerPrivacySegmentedControlPublic;
    self.viewerPrivacySegmentedControl.crossFadeLabelsOnDrag = YES;
    self.viewerPrivacySegmentedControl.height = 25;
    self.viewerPrivacySegmentedControl.font = [UIFont fontWithName:STORY_FONT size:12];
    self.viewerPrivacySegmentedControl.thumb.tintColor = BANYAN_GREEN_COLOR;
    self.viewerPrivacySegmentedControl.tintColor = BANYAN_BROWN_COLOR;
    self.viewerPrivacySegmentedControl.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 3);
    self.viewerPrivacySegmentedControl.textColor = BANYAN_WHITE_COLOR;
    
    self.inviteViewersButton.enabled = NO;
    [self updateContentSize];
    
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.scrollView addSubview:self.contributorPrivacySegmentedControl];
    [self.scrollView addSubview:self.viewerPrivacySegmentedControl];
    self.contributorPrivacySegmentedControl.center = CGPointMake(160, 78);
    self.viewerPrivacySegmentedControl.center = CGPointMake(160, 132);
    
    // Tags
    self.tagsFieldView.scrollEnabled = NO;
    [self.tagsFieldView.tokenField setDelegate:self];
	[self.tagsFieldView.tokenField addTarget:self action:@selector(tokenFieldFrameDidChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
	[self.tagsFieldView.tokenField setTokenizingCharacters:[NSCharacterSet characterSetWithCharactersInString:@",;."]]; // Default is a comma
    [self.tagsFieldView.tokenField addTarget:self action:@selector(tokenFieldChangedEditing:) forControlEvents:UIControlEventEditingDidBegin];
	[self.tagsFieldView.tokenField addTarget:self action:@selector(tokenFieldChangedEditing:) forControlEvents:UIControlEventEditingDidEnd];
    self.tagsFieldView.tokenField.returnKeyType = UIReturnKeyDone;
    [self.tagsFieldView.tokenField setPromptText:@"Add some tags..."];
    if (!self.locationManager) {
        self.locationManager = [[BNLocationManager alloc] initWithDelegate:self];
    }
    [self.inviteViewersButton addTarget:self action:@selector(inviteViewers) forControlEvents:UIControlEventTouchUpInside];
    [self.inviteContributorsButton addTarget:self action:@selector(inviteContributors) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidUnload
{
    [self setStoryTitle:nil];
    [self setStoryTitleTextField:nil];
    [self setTapRecognizer:nil];
    [self setInvitedToViewList:nil];
    [self setInvitedToContributeList:nil];
    [self setInviteContributorsButton:nil];
    [self setInviteViewersButton:nil];
    [self setLocationManager:nil];
    [self setTagsFieldView:nil];
    [self setAddLocationButton:nil];
    [self setAddPhotoButton:nil];
    [self setScrollView:nil];
    [self setContributorPrivacySegmentedControl:nil];
    [self setViewerPrivacySegmentedControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark- Target Actions for new story
- (NSString *)defaultStoryTitle
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    return [dateFormatter stringFromDate:[NSDate date]];
}

// Save the new story added
- (IBAction)doneNewStory:(UIBarButtonItem *)sender 
{
    // Title
    self.story.title = ![self.storyTitleTextField.text isEqualToString:@""] ? self.storyTitleTextField.text : [self defaultStoryTitle];
    
    // Story Privacy
    NSMutableDictionary *contributorsDictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary *viewersDictionary = [NSMutableDictionary dictionary];

    [contributorsDictionary setObject:[self contributorScope] forKey:kBNStoryPrivacyScope];
    [contributorsDictionary setObject:[self contributorsInvited] forKey:kBNStoryPrivacyInviteeList];
    
    [viewersDictionary setObject:[self viewerScope] forKey:kBNStoryPrivacyScope];
    [viewersDictionary setObject:[self viewersInvited] forKey:kBNStoryPrivacyInviteeList];
    
    self.story.writeAccess = contributorsDictionary;
    self.story.readAccess = viewersDictionary;
    
    // Story Location
    if (self.isLocationEnabled == YES) {
        self.story.isLocationEnabled = [NSNumber numberWithBool:YES];
        if (self.locationManager.location) {
            
            CLLocationCoordinate2D coord = self.locationManager.location.coordinate;
            self.story.latitude = [NSNumber numberWithDouble:coord.latitude];
            self.story.longitude = [NSNumber numberWithDouble:coord.longitude];
            self.story.geocodedLocation = self.locationManager.location.name;
        }
    } else  {
        self.story.isLocationEnabled = NO;
    }
    
    NSArray *tagsArray = [self.tagsFieldView tokenTitles];
    NSString *tags = [tagsArray componentsJoinedByString:@","];
    self.story.tags = tags;
    NSLog(@"tags are %@", tags);
    
    // Upload Story
    self.story = [Story createNewStory:self.story];

    NSLog(@"New story %@ saved", self.story);
    [self.delegate newStoryViewController:self didAddStory:self.story];
    [TestFlight passCheckpoint:@"New Story created successfully"];
}

- (IBAction)cancel:(id)sender
{
    [self.delegate newStoryViewControllerDidCancel:self];
}

# pragma mark story privacy

- (void) storyPrivacySegmentedControlChangedValue:(SVSegmentedControl *)segmentedControl
{
    if (segmentedControl == self.contributorPrivacySegmentedControl) {
        if (segmentedControl.selectedIndex == ContributorPrivacySegmentedControlInvited){
            self.inviteContributorsButton.enabled = YES;
            self.viewerPrivacySegmentedControl.enabled = YES;
            self.viewerPrivacySegmentedControl.alpha = 1;
        } else {
            if (self.viewerPrivacySegmentedControl.selectedIndex != ViewerPrivacySegmentedControlPublic) {
                [self.viewerPrivacySegmentedControl setSelectedIndex:ViewerPrivacySegmentedControlPublic animated:YES];
            }
            self.viewerPrivacySegmentedControl.enabled = NO;
            self.viewerPrivacySegmentedControl.alpha = 0.5;
            self.inviteContributorsButton.enabled = NO;
        }
    } else if (segmentedControl == self.viewerPrivacySegmentedControl) {
        if (self.viewerPrivacySegmentedControl.selectedIndex == ViewerPrivacySegmentedControlInvited) {
            self.inviteViewersButton.enabled = 1;
        } else {
            self.inviteViewersButton.enabled = 0;
        }
    } else {
        assert(false);
    }
    
}

- (NSString *)contributorScope
{
    if (self.contributorPrivacySegmentedControl.selectedIndex == ContributorPrivacySegmentedControlInvited) {
        return kBNStoryPrivacyScopeInvited;
    } else {
        return kBNStoryPrivacyScopePublic;
    }
}

- (NSDictionary *)contributorsInvited
{
    User *currentUser = [User currentUser];
    if (currentUser) {
        NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                        currentUser.name, @"name",
                                        currentUser.facebookId, @"id", nil];
        [self.invitedToContributeList addObject:selfInvitation];
    } else {
        if (HAVE_ASSERTS)
            assert(false);
        return nil;
    }
    return [NSDictionary dictionaryWithObject:self.invitedToContributeList forKey:kBNStoryPrivacyInvitedFacebookFriends];
}

- (NSString *)viewerScope
{
    switch (self.viewerPrivacySegmentedControl.selectedIndex) {
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
    User *currentUser = [User currentUser];
    if (currentUser) {
        NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                        currentUser.name, @"name",
                                        currentUser.facebookId, @"id", nil];
        [self.invitedToViewList addObject:selfInvitation];
    } else {
        if (HAVE_ASSERTS)
            assert(false);
        return nil;
    }
    return [NSDictionary dictionaryWithObject:self.invitedToViewList forKey:kBNStoryPrivacyInvitedFacebookFriends];
}

# pragma mark location settings
- (IBAction)showLocationSwitchToggled:(UISwitch *)sender
{
    if (self.isLocationEnabled) {
        [self.locationManager beginUpdatingLocation];
        [self.addLocationButton.titleLabel setHidden:NO];
    } else {
        [self.locationManager stopUpdatingLocation:self.locationManager.locationStatus];
        [self.addLocationButton.titleLabel setHidden:YES];
    }
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
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    self.keyboardIsShown = NO;
}

- (void)unregisterForKeyboardNotifications
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification 
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification 
                                                  object:nil];
    
    self.keyboardIsShown = NO;
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    if (self.keyboardIsShown)
        return;

    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    CGPoint activeFieldOrigin = self.activeField.frame.origin;
    if (self.activeField == self.tagsFieldView.tokenField) {
        activeFieldOrigin = self.tagsFieldView.frame.origin;
        activeFieldOrigin.y += self.tagsFieldView.frame.size.height;
    }
    
    if (!CGRectContainsPoint(aRect, activeFieldOrigin)) {
        CGPoint scrollPoint = CGPointMake(0.0, activeFieldOrigin.y-kbSize.height);
        [self.scrollView setContentOffset:scrollPoint animated:YES];
    }
    
    self.keyboardIsShown = YES;
}

// Called when the UIKeyboardWillBeHidden is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    if(!self.keyboardIsShown)
        return;
    
    [self.scrollView setContentOffset:CGPointZero animated:YES];
    
    self.keyboardIsShown = NO;
}

-(void)didTapAnywhere: (UITapGestureRecognizer*) recognizer {    
    [self dismissKeyboard:NULL];
}

- (IBAction)dismissKeyboard:(id)sender 
{
    if (self.storyTitleTextField.isFirstResponder)
        [self.storyTitleTextField resignFirstResponder];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


# pragma invite friends

- (void) inviteViewers
{
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] initWithStyle:UITableViewStylePlain];
    invitedTableViewController.invitationType = INVITED_VIEWERS_STRING;
    invitedTableViewController.delegate = self;
    invitedTableViewController.selectedContacts = self.invitedToViewList;
    [self.navigationController pushViewController:invitedTableViewController animated:YES];
}

- (void) inviteContributors
{
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] initWithStyle:UITableViewStylePlain];
    invitedTableViewController.invitationType = INVITED_CONTRIBUTORS_STRING;
    invitedTableViewController.delegate = self;
    invitedTableViewController.selectedContacts = self.invitedToContributeList;
    [self.navigationController pushViewController:invitedTableViewController animated:YES];
}

# pragma mark InvitedTableViewControllerDelegate
- (void) invitedTableViewController:(InvitedTableViewController *)invitedTableViewController 
                   finishedInviting:(NSString *)invitingType 
                       withContacts:(NSArray *)contactsList
{
    if ([invitingType isEqualToString:INVITED_CONTRIBUTORS_STRING])
    {
        [self.invitedToContributeList setArray:contactsList];
        // All contributors invited are also viewers!
        [self.invitedToViewList addObjectsFromArray:contactsList];
    }
    else if ([invitingType isEqualToString:INVITED_VIEWERS_STRING]) 
    {
        [self.invitedToViewList setArray:contactsList];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) invitedTableViewControllerDidCancel:(InvitedTableViewController *)invitedTableViewController
{
    [self.navigationController popViewControllerAnimated:YES];
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
    [self updateContentSize];
}

- (void) updateContentSize
{
    CGSize screenSize = [UIScreen mainScreen].applicationFrame.size;
    self.scrollView.contentSize = CGSizeMake(screenSize.width,
                                             screenSize.height
                                                - self.navigationController.navigationBar.frame.size.height
                                                + self.tagsFieldView.contentView.frame.origin.y
                                                - self.tagsFieldView.contentView.frame.size.height);
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end

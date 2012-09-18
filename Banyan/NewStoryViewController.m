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

@interface NewStoryViewController ()
{
    NSInteger contributors;
    NSInteger viewers;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) NSString *storyTitle;
@property (weak, nonatomic) IBOutlet UITextField *storyTitleTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *contributorSegmentedControl;
@property (weak, nonatomic) IBOutlet UISlider *viewerSlider;
@property (weak, nonatomic) IBOutlet UIView *addStorySubView;
@property (weak, nonatomic) IBOutlet UIButton *inviteContributorsButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteViewersButton;
@property (weak, nonatomic) IBOutlet UILabel *contributorInvitationLabel;
@property (weak, nonatomic) IBOutlet UISwitch *showLocationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@property (strong, nonatomic) NSMutableArray *invitedToViewList;
@property (strong, nonatomic) NSMutableArray *invitedToContributeList;

@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

@property (strong, nonatomic) NSMutableDictionary *storyAttributes;
@property (nonatomic) BOOL keyboardIsShown;

@property (strong, nonatomic) BNLocationManager *locationManager;

@end

@implementation NewStoryViewController

// These correspond to the index for UISegmentedControl and UISlider
typedef enum {
    StoryPrivacySegmentIndexInvited = 0,
    StoryPrivacySegmentIndexLimited = 1,
    StoryPrivacySegmentIndexPublic = 2,
} StoryPrivacySegmentIndex;

// Timeout for finding location
#define kFindLocationTimeOut 0.5*60 // half a minute

@synthesize scrollView = _scrollView;
@synthesize storyTitle = _storyTitle;
@synthesize storyTitleTextField = _storyTitleTextField;
@synthesize contributorSegmentedControl = _contributorSegmentedControl;
@synthesize viewerSlider = _viewerSlider;
@synthesize addStorySubView = _addStorySubView;
@synthesize delegate = _delegate;
@synthesize keyboardIsShown = _keyboardIsShown;
@synthesize tapRecognizer = _tapRecognizer;
@synthesize invitedToViewList = _invitedToViewList;
@synthesize invitedToContributeList = _invitedToContributeList;
@synthesize inviteContributorsButton = _inviteContributorsButton;
@synthesize inviteViewersButton = _inviteViewersButton;
@synthesize contributorInvitationLabel = _contributorInvitationLabel;
@synthesize showLocationSwitch = _showLocationSwitch;
@synthesize locationLabel = _locationLabel;
@synthesize storyAttributes = _storyAttributes;
@synthesize locationManager = _locationManager;
/*
- (id)init
{
    if (self = [super init]) {
        CGRect screenSize = [[UIScreen mainScreen] bounds];
        
        self.title = @"New Story";

        // Navigation Bar
        UIBarButtonItem *createButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleDone target:self action:@selector(doneNewStory:)];
        self.navigationItem.rightBarButtonItem.title = @"Create";
        self.navigationItem.rightBarButtonItem = createButton;
        
        // Scroll View
        self.scrollView = [[UIScrollView alloc] initWithFrame:screenSize];
        self.scrollView.contentSize = screenSize.size;
        [self.view addSubview:self.scrollView];
                
        self.addStorySubView = [[UIView alloc] initWithFrame:screenSize];
        [self.scrollView addSubview:self.addStorySubView];
        
        // Story Title
        self.storyTitleTextField = [[UITextField alloc] initWithFrame:CGRectMake(20.0f, 10.0f, screenSize.size.width - 20.0f, 62.0f)];
        self.storyTitleTextField.placeholder = @"New Story Title";
        self.storyTitleTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.storyTitleTextField.textAlignment = UITextAlignmentCenter;
        [self.addStorySubView addSubview:self.storyTitleTextField];
        
        // Location settings
        UILabel *locationPlaceHolder = [[UILabel alloc] initWithFrame:CGRectMake(90.0f, 10.0f, 190.0f, 20.0f)];
        locationPlaceHolder.text = @"Show Location with Story";
        locationPlaceHolder.font = [UIFont fontWithName:@"HelveticaNeue" size:17];
        [self.addStorySubView addSubview:locationPlaceHolder];
        
        self.locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0f, 10.0f, 180.0f, 12.0f)];
        self.locationLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
        self.locationLabel.textColor = [UIColor darkGrayColor];
        self.locationLabel.numberOfLines = 1;
        self.locationLabel.minimumFontSize = 10;
        self.locationLabel.adjustsFontSizeToFitWidth = YES;
        [self.addStorySubView addSubview:self.locationLabel];
        
        self.showLocationSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(90.0f, 200.0f, 40.0f, 20.0f)];
        self.showLocationSwitch.on = YES;
        [self.addStorySubView addSubview:self.showLocationSwitch];
    }
    return self;
}
*/
- (void)loadView
{
    [super loadView];
    NSLog(@"Loading view");
}

- (NSString *) storyTitle
{
    return self.storyTitleTextField.text;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self registerForKeyboardNotifications];
    self.locationManager = [[BNLocationManager alloc] init];
    self.locationManager.delegate = self;
    if (self.showLocationSwitch.on) {
        [self.locationManager beginUpdatingLocation];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self unregisterForKeyboardNotifications];
    if (self.showLocationSwitch.on) {
        [self.locationManager stopUpdatingLocation:self.locationLabel.text];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.inviteContributorsButton.alpha = 0;
    
    self.storyTitleTextField.delegate = self;
    [self.storyTitleTextField becomeFirstResponder];
    self.storyTitleTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    self.invitedToContributeList = [NSMutableArray array];
    self.invitedToViewList = [NSMutableArray array];
    self.storyAttributes = [NSMutableDictionary dictionary];
    
    self.viewerSlider.value = StoryPrivacySegmentIndexLimited;
    self.inviteViewersButton.alpha = 0;
}

- (void)viewDidUnload
{
    [self setStoryTitle:nil];
    [self setStoryTitleTextField:nil];
    [self setContributorSegmentedControl:nil];
    [self setTapRecognizer:nil];
    [self setAddStorySubView:nil];
    [self setInvitedToViewList:nil];
    [self setInvitedToContributeList:nil];
    [self setInviteContributorsButton:nil];
    [self setInviteViewersButton:nil];
    [self setContributorInvitationLabel:nil];
    [self setShowLocationSwitch:nil];
    [self setLocationLabel:nil];
    [self setStoryAttributes:nil];
    [self setScrollView:nil];
    self.locationManager.delegate = nil;
    [self setLocationManager:nil];
    [self setViewerSlider:nil];
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
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"User Info"];
    if (userInfo)
    {
        NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [userInfo objectForKey:@"name"], 
                                        @"name", 
                                        [userInfo objectForKey:@"id"], 
                                        @"id", nil];
        [self.invitedToViewList addObject:selfInvitation];
        [self.invitedToContributeList addObject:selfInvitation];
    } else {
        NSLog(@"NewStoryViewController:doneNewStory:sender "
              "Cound not invite self");
    }
    
    [self.storyAttributes setObject:![self.storyTitle isEqualToString:@""] ? self.storyTitle : [self defaultStoryTitle]
                          forKey:STORY_TITLE];
    
    if (self.contributorSegmentedControl.selectedSegmentIndex == StoryPrivacySegmentIndexPublic) {
        // This is a publically contributable story
        [self.storyAttributes setObject:[NSNumber numberWithBool:YES]
                          forKey:STORY_PUBLIC_CONTRIBUTORS];
        
        [self.storyAttributes setObject:[NSNumber numberWithBool:YES]                          
                              forKey:STORY_PUBLIC_VIEWERS];
    } else {
        // This is not a publically contributable story
        [self.storyAttributes setObject:[NSNumber numberWithBool:NO]
                              forKey:STORY_PUBLIC_CONTRIBUTORS];
        
        [self.storyAttributes setObject:self.invitedToContributeList forKey:STORY_INVITED_TO_CONTRIBUTE];
        
        if (self.viewerSlider.value == StoryPrivacySegmentIndexPublic) {
            [self.storyAttributes setObject:[NSNumber numberWithBool:YES] forKey:STORY_PUBLIC_VIEWERS];

        } else {
            [self.storyAttributes setObject:[NSNumber numberWithBool:NO] forKey:STORY_PUBLIC_VIEWERS];
            [self.storyAttributes setObject:self.invitedToViewList forKey:STORY_INVITED_TO_VIEW];
        }
        
    }

    if (self.showLocationSwitch.on == YES) {
        [self.storyAttributes setObject:[NSNumber numberWithBool:YES] forKey:STORY_LOCATION_ENABLED];
        if (self.locationManager.location) {
            
            CLLocationCoordinate2D coord = [self.locationManager.location coordinate];
            
            [self.storyAttributes setObject:[NSNumber numberWithDouble:coord.latitude]
                                     forKey:STORY_LATITUDE];
            [self.storyAttributes setObject:[NSNumber numberWithDouble:coord.longitude]
                                     forKey:STORY_LONGITUDE];
            [self.storyAttributes setObject:REPLACE_NIL_WITH_NULL(self.locationManager.locationString) forKey:STORY_GEOCODEDLOCATION];
        }
    } else  {
        [self.storyAttributes setObject:[NSNumber numberWithBool:NO] forKey:STORY_LOCATION_ENABLED];
    }
    
    Story *story = [Story createStoryWithAttributes:self.storyAttributes];
    if (story)
    {
        NSLog(@"New story %@ saved", story);
        [self.delegate newStoryViewController:self didAddStory:story];
        [TestFlight passCheckpoint:@"New Story created successfully"];
    } else {
        NSLog(@"Error saving new story %@", self.storyTitle);
        [TestFlight passCheckpoint:@"New Story could not be created successfully"];
    }
}

- (IBAction)storyContributors:(UISegmentedControl *)sender 
{
    if (sender.selectedSegmentIndex == StoryPrivacySegmentIndexInvited)
    {
        [self.viewerSlider setValue:StoryPrivacySegmentIndexLimited animated:YES];
    } else {
        [self.viewerSlider setValue:StoryPrivacySegmentIndexPublic animated:YES];
    }
}

- (IBAction)sliderChanged:(UISlider *)sender
{
    int sliderValue;
    sliderValue = lroundf(sender.value);
    [self.viewerSlider setValue:sliderValue animated:YES];
    if (self.viewerSlider.value == StoryPrivacySegmentIndexInvited) {
        self.inviteViewersButton.alpha = 1;
    } else {
        self.inviteViewersButton.alpha = 0;
    }
}


# pragma mark location settings
- (IBAction)showLocationSwitchToggled:(UISwitch *)sender
{
    if (self.showLocationSwitch.on) {
        [self.locationManager beginUpdatingLocation];
    } else {
        [self.locationManager stopUpdatingLocation:nil];
    }
}

# pragma mark BNLocationManagerDelegate
- (void) locationUpdated
{   
    self.locationLabel.text = self.locationManager.locationStatus;
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
    
    [self.addStorySubView addGestureRecognizer:self.tapRecognizer];
    self.keyboardIsShown = YES; 
}

// Called when the UIKeyboardWillBeHidden is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    if(!self.keyboardIsShown)
        return;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    [self.addStorySubView removeGestureRecognizer:self.tapRecognizer];
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


# pragma mark segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Add Contributors"])
    {
        InvitedTableViewController *invitedTableViewController = segue.destinationViewController;
        invitedTableViewController.invitationType = INVITED_CONTRIBUTORS_STRING;
        invitedTableViewController.delegate = self;
        invitedTableViewController.selectedContacts = self.invitedToContributeList;
        
    } else if ([segue.identifier isEqualToString:@"Add Viewers"])
    {
        InvitedTableViewController *invitedTableViewController = segue.destinationViewController;
        invitedTableViewController.invitationType = INVITED_VIEWERS_STRING;
        invitedTableViewController.delegate = self;
        invitedTableViewController.selectedContacts = self.invitedToViewList;
    }
    
}
# pragma mark InvitedTableViewControllerDelegate
- (void) invitedTableViewController:(InvitedTableViewController *)invitedTableViewController 
                   finishedInviting:(NSString *)invitingType 
                       withContacts:(NSArray *)contactsList
{
    if ([invitingType isEqualToString:INVITED_CONTRIBUTORS_STRING])
    {
        [self.invitedToContributeList setArray:contactsList];
    }
    else if ([invitingType isEqualToString:INVITED_VIEWERS_STRING]) 
    {
        [self.invitedToViewList setArray:contactsList];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end

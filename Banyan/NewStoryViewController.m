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
@property (weak, nonatomic) IBOutlet UISegmentedControl *contributorSegmenedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *viewerSegmentedControl;
@property (weak, nonatomic) IBOutlet UIView *addStorySubView;
@property (weak, nonatomic) IBOutlet UILabel *readStoryLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteContributorsButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteViewersButton;
@property (weak, nonatomic) IBOutlet UILabel *viewerInvitationLabel;
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

// These correspond to the index for UISegmentedControl
#define PUBLIC 0
#define INVITED 1

// Timeout for finding location
#define kFindLocationTimeOut 0.5*60 // half a minute

@synthesize scrollView = _scrollView;
@synthesize storyTitle = _storyTitle;
@synthesize storyTitleTextField = _storyTitleTextField;
@synthesize contributorSegmenedControl = _contributorSegmenedControl;
@synthesize viewerSegmentedControl = _viewerSegmentedControl;
@synthesize addStorySubView = _addStorySubView;
@synthesize readStoryLabel = _readStoryLabel;
@synthesize delegate = _delegate;
@synthesize keyboardIsShown = _keyboardIsShown;
@synthesize tapRecognizer = _tapRecognizer;
@synthesize invitedToViewList = _invitedToViewList;
@synthesize invitedToContributeList = _invitedToContributeList;
@synthesize inviteContributorsButton = _inviteContributorsButton;
@synthesize inviteViewersButton = _inviteViewersButton;
@synthesize viewerInvitationLabel = _viewerInvitationLabel;
@synthesize contributorInvitationLabel = _contributorInvitationLabel;
@synthesize showLocationSwitch = _showLocationSwitch;
@synthesize locationLabel = _locationLabel;
@synthesize storyAttributes = _storyAttributes;
@synthesize locationManager = _locationManager;

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
    
    self.viewerSegmentedControl.alpha = 0;
    self.inviteViewersButton.alpha = 0;
    self.inviteContributorsButton.alpha = 0;
    self.viewerInvitationLabel.alpha = 0;
    
    self.storyTitleTextField.delegate = self;
    [self.storyTitleTextField becomeFirstResponder];
    self.storyTitleTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    self.invitedToContributeList = [NSMutableArray array];
    self.invitedToViewList = [NSMutableArray array];
    self.storyAttributes = [NSMutableDictionary dictionary];
    self.scrollView.contentSize = CGSizeMake(self.addStorySubView.frame.size.width, self.addStorySubView.frame.size.height);
}

- (void)viewDidUnload
{
    [self setStoryTitle:nil];
    [self setStoryTitleTextField:nil];
    [self setContributorSegmenedControl:nil];
    [self setViewerSegmentedControl:nil];
    [self setTapRecognizer:nil];
    [self setAddStorySubView:nil];
    [self setReadStoryLabel:nil];
    [self setInvitedToViewList:nil];
    [self setInvitedToContributeList:nil];
    [self setInviteContributorsButton:nil];
    [self setInviteViewersButton:nil];
    [self setViewerInvitationLabel:nil];
    [self setContributorInvitationLabel:nil];
    [self setShowLocationSwitch:nil];
    [self setLocationLabel:nil];
    [self setStoryAttributes:nil];
    [self setScrollView:nil];
    self.locationManager.delegate = nil;
    [self setLocationManager:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark- Target Actions for new story

// Show and hide the viewer segmented control
- (void) showViewerSegmentedControl
{
    self.readStoryLabel.text = @"Who can read the story?";
    self.viewerSegmentedControl.alpha = 1;
    self.inviteViewersButton.alpha = self.viewerSegmentedControl.selectedSegmentIndex == INVITED ? 1 : 0;
    self.inviteContributorsButton.alpha = 1;
    self.viewerInvitationLabel.alpha = 1;
}

- (void) hideViewerSegmentedControl
{
    self.readStoryLabel.text = @"Anyone can read the story.";
    self.viewerSegmentedControl.alpha = 0;
    self.inviteViewersButton.alpha = 0;
    self.inviteContributorsButton.alpha = 0;
    self.viewerInvitationLabel.alpha = 0;
}

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
    if (self.contributorSegmenedControl.selectedSegmentIndex == PUBLIC) {
        [self.storyAttributes setObject:[NSNumber numberWithBool:YES]
                          forKey:STORY_PUBLIC_CONTRIBUTORS];
        
        [self.storyAttributes setObject:[NSNumber numberWithBool:YES]                          
                              forKey:STORY_PUBLIC_VIEWERS];
    } else {
        [self.storyAttributes setObject:[NSNumber numberWithBool:NO]
                              forKey:STORY_PUBLIC_CONTRIBUTORS];
        
        [self.storyAttributes setObject:self.invitedToContributeList forKey:STORY_INVITED_TO_CONTRIBUTE];
        
        if (self.viewerSegmentedControl.selectedSegmentIndex == PUBLIC) {
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
    if (sender.selectedSegmentIndex == INVITED)
    {
        [self showViewerSegmentedControl];
    } else {
        [self hideViewerSegmentedControl];
    }
}

- (IBAction)storyViewers:(UISegmentedControl *)sender 
{
    if (sender.selectedSegmentIndex == INVITED)
    {
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

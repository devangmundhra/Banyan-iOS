//
//  ModifyStoryViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 3/10/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "ModifyStoryViewController.h"
#import "Story_Defines.h"
#import "BanyanAppDelegate.h"
#import "Story+Create.h"
#import "User.h"
#import <QuartzCore/QuartzCore.h>
#import "BNMisc.h"
#import "Story+Permissions.h"
#import "BNLabel.h"
#import "BNTextField.h"

@interface ModifyStoryViewController ()

@property (strong, nonatomic) NSString *storyTitle;
@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet BNTextField *storyTitleTextField;

@property (strong, nonatomic) IBOutlet UIView *invitationView;
@property (strong, nonatomic) IBOutlet BNLabel *inviteeLabel;
@property (strong, nonatomic) IBOutlet UIButton *inviteContactsButton;


@property (strong, nonatomic) BNPermissionsObject *writeAccessList;
@property (strong, nonatomic) BNPermissionsObject *readAccessList;

@property (nonatomic) ModifyStoryViewControllerEditMode editMode;
@property (strong, nonatomic) Story *backupStory_;

@end

@implementation ModifyStoryViewController

@synthesize storyTitle = _storyTitle;
@synthesize storyTitleTextField = _storyTitleTextField;
@synthesize writeAccessList = _writeAccessList;
@synthesize readAccessList = _readAccessList;
@synthesize backupStory_ = _backupStory_;
@synthesize editMode = _editMode;
@synthesize delegate = _delegate;
@synthesize inviteeLabel = _inviteeLabel;
@synthesize inviteContactsButton = _inviteContactsButton;
@synthesize scrollView = _scrollView;
@synthesize invitationView = _invitationView;

#define TEXT_INSETS 5
#define VIEW_INSETS 8

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        // this should never be called directly.
        // initWithStory should be called instead
        if (HAVE_ASSERTS)
            assert(false);
    }
    return self;
}

- (id) initWithStory:(Story *)story
{
    if (self = [super init]) {
        self.hidesBottomBarWhenPushed = YES;
        self.story = story;
        if (self.story.remoteStatus == RemoteObjectStatusLocal) {
            self.editMode = ModifyStoryViewControllerEditModeAdd;
        } else {
            self.editMode = ModifyStoryViewControllerEditModeEdit;
            self.backupStory_ = [NSEntityDescription insertNewObjectForEntityForName:[[story entity] name] inManagedObjectContext:[story managedObjectContext]];
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
    
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.scrollView setContentSize:self.view.bounds.size];
    self.scrollView.scrollEnabled = NO;
    [self.view addSubview:self.scrollView];
    
    CGRect frame = self.scrollView.bounds;
    frame.origin.x = VIEW_INSETS;
    frame.size = self.scrollView.bounds.size;
    frame.size.height = 44.0f;
    frame.size.width -= 2*VIEW_INSETS;
    frame.origin.y = 16.0f;
    self.storyTitleTextField = [[BNTextField alloc] initWithFrame:frame];
    self.storyTitleTextField.backgroundColor = [BANYAN_GREEN_COLOR colorWithAlphaComponent:0.2];
    self.storyTitleTextField.placeholder = @"What do you want to call your story?";
    self.storyTitleTextField.delegate = self;
    self.storyTitleTextField.textEdgeInsets = UIEdgeInsetsMake(0, TEXT_INSETS, 0, TEXT_INSETS);
    self.storyTitleTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.storyTitleTextField.font = [UIFont fontWithName:@"Roboto-Bold" size:16];
    self.storyTitleTextField.returnKeyType = UIReturnKeyDone;
    [self.storyTitleTextField.layer setCornerRadius:8];
    [self.scrollView addSubview:self.storyTitleTextField];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    [self.scrollView addGestureRecognizer:tapRecognizer];

    frame.origin.y = CGRectGetMaxY(self.storyTitleTextField.frame) + 44 /* distance between caption and permission */;
    self.invitationView = [[UIView alloc] initWithFrame:frame];
    self.invitationView.backgroundColor = [BANYAN_GREEN_COLOR colorWithAlphaComponent:0.1];
    [self.invitationView.layer setCornerRadius:8];
    [self.scrollView addSubview:self.invitationView];
    
    frame = self.invitationView.bounds;
    self.inviteeLabel = [[BNLabel alloc] initWithFrame:frame];
    self.inviteeLabel.textEdgeInsets = UIEdgeInsetsMake(TEXT_INSETS, TEXT_INSETS, TEXT_INSETS, TEXT_INSETS);
    self.inviteeLabel.backgroundColor = [BANYAN_GREEN_COLOR colorWithAlphaComponent:0.1];
    [self.inviteeLabel.layer setCornerRadius:8];
    self.inviteeLabel.numberOfLines = 0;
    [self.invitationView addSubview:self.inviteeLabel];

    self.inviteContactsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.inviteContactsButton setTitle:@"Change permissions" forState:UIControlStateNormal];
    frame.origin.y = CGRectGetMaxY(self.inviteeLabel.frame);
    self.inviteContactsButton.frame = frame;
    [self.invitationView addSubview:self.inviteContactsButton];
    
    // Default is selected permissions for writers
    self.writeAccessList = [BNPermissionsObject permissionObject];
    self.writeAccessList.scope = kBNStoryPrivacyScopeInvited;

    // Default is limited permissions for viewers
    self.readAccessList = [BNPermissionsObject permissionObject];
    self.readAccessList.scope = kBNStoryPrivacyScopeLimited;
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (HAVE_ASSERTS)
        NSAssert(currentUser, @"No Current user available when modifying story");
    if (currentUser) {
        NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                        currentUser.name, @"name",
                                        currentUser.facebookId, @"id", nil];
        self.readAccessList.facebookInvitedList = [NSMutableArray arrayWithObject:selfInvitation];
    }

    if (self.editMode == ModifyStoryViewControllerEditModeEdit) {
        // Set the title and permissions
        self.storyTitleTextField.text = self.story.title;
        // Contributors
        self.writeAccessList = [BNPermissionsObject permissionObjectWithDictionary:self.story.writeAccess];
        // Viewers
        self.readAccessList = [BNPermissionsObject permissionObjectWithDictionary:self.story.readAccess];
        
        self.title = @"Edit Story";
    } else {
        self.title = @"Add Story";
    }
    
    [self.inviteContactsButton addTarget:self action:@selector(inviteContacts:) forControlEvents:UIControlEventTouchUpInside];
    [self updatePermissionTextInView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark- Target Actions for story

- (void) inviteContacts:(id)sender
{
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] initWithViewerPermissions:[self.readAccessList copy]
                                                                                                     contributorPermission:[self.writeAccessList copy]];
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
    if (self.backupStory_)
        [self.story cloneFrom:self.backupStory_];
}

- (IBAction)done:(UIBarButtonItem *)sender
{
    [self dismissKeyboard:nil];
    // Title
    self.story.title = (self.storyTitleTextField.text && ![self.storyTitleTextField.text isEqualToString:@""]) ? self.storyTitleTextField.text : [BNMisc longCurrentDate];
    
    // Story Privacy
    self.story.writeAccess = [self.writeAccessList permissionsDictionary];
    self.story.readAccess = [self.readAccessList permissionsDictionary];
    
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

# pragma mark Instance methods
- (void) updatePermissionTextInView
{
    NSString *permStr = [NSString stringWithFormat:@"%@ can contribute to the story.\r%@ can view the story.",
                         [self.writeAccessList stringifyPermissionObject], [self.readAccessList stringifyPermissionObject]];
    NSMutableAttributedString *labelStr =[[NSMutableAttributedString alloc] initWithString:@"Who can contribute or view the story?"
                                                                                attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                                                             NSForegroundColorAttributeName: [UIColor grayColor]}];
    
    [labelStr appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\r\r"
                                                                            attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:8]}]];
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:permStr
                                                                             attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:12]}];
    [attr setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:14]}
                  range:[permStr rangeOfString:[self.writeAccessList stringifyPermissionObject]]];
    [attr setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:14]}
                  range:[permStr rangeOfString:[NSString stringWithFormat:@"\r%@", [self.readAccessList stringifyPermissionObject]]]];

    [labelStr appendAttributedString:attr];
    [self.inviteeLabel setAttributedText:labelStr];

    CGSize expectedSize = [labelStr boundingRectWithSize:self.scrollView.bounds.size
                                             options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                             context:nil].size;
    
    CGRect frame = self.inviteeLabel.frame;
    frame.size.height = roundf(expectedSize.height) + 2*TEXT_INSETS + 2*TEXT_INSETS;
    self.inviteeLabel.frame = frame;
    
    frame = self.inviteContactsButton.frame;
    frame.origin.y = CGRectGetMaxY(self.inviteeLabel.frame);
    self.inviteContactsButton.frame = frame;
    
    frame = self.invitationView.frame;
    frame.size.height = CGRectGetHeight(self.inviteeLabel.frame) + CGRectGetHeight(self.inviteContactsButton.frame);
    self.invitationView.frame = frame;
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
//    NSDictionary* info = [aNotification userInfo];
//    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
//    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
}

// Called when the UIKeyboardWillBeHidden is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
//    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
}

-(void)didTapAnywhere: (UITapGestureRecognizer*) recognizer
{
    [self dismissKeyboard:NULL];
}

- (IBAction)dismissKeyboard:(id)sender
{
    if (self.storyTitleTextField.isFirstResponder)
        [self.storyTitleTextField resignFirstResponder];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

# pragma mark InvitedTableViewControllerDelegate
- (void) invitedTableViewController:(InvitedTableViewController *)invitedTableViewController
finishedInvitingForViewerPermissions:(BNPermissionsObject *)viewerPermissions
             contributorPermissions:(BNPermissionsObject *)contributorPermissions
{
    self.readAccessList = viewerPermissions;
    self.writeAccessList = contributorPermissions;
    [self updatePermissionTextInView];
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

#undef TEXT_INSETS
#undef VIEW_INSETS

@end

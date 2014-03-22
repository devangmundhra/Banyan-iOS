//
//  ModifyStoryViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 3/10/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "ModifyStoryViewController.h"
#import "BanyanAppDelegate.h"
#import "Story+Create.h"
#import "User.h"
#import <QuartzCore/QuartzCore.h>
#import "BNMisc.h"
#import "Story+Permissions.h"
#import "BNLabel.h"
#import "BNTextField.h"
#import "Story+Edit.h"

@interface ModifyStoryViewController (UIActionSheetDelegate) <UIActionSheetDelegate>
@end

@interface ModifyStoryViewController (UITextFieldDelegate) <UITextFieldDelegate>
@end

@interface ModifyStoryViewController ()

@property (strong, nonatomic) NSString *storyTitle;
@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet BNTextField *storyTitleTextField;
@property (strong, nonatomic) UILabel *charCountLabel;
@property (strong, nonatomic) IBOutlet UIView *invitationView;
@property (strong, nonatomic) IBOutlet BNLabel *inviteeLabel;
@property (strong, nonatomic) IBOutlet UIButton *inviteContactsButton;

@property (strong, nonatomic) BNPermissionsObject<BNPermissionsObject> *writeAccessList;
@property (strong, nonatomic) BNPermissionsObject<BNPermissionsObject> *readAccessList;

@property (nonatomic) ModifyStoryViewControllerEditMode editMode;

@property (strong, nonatomic) NSManagedObjectContext *scratchMOC;;
@end

@implementation ModifyStoryViewController

@synthesize storyTitle = _storyTitle;
@synthesize storyTitleTextField = _storyTitleTextField;
@synthesize writeAccessList = _writeAccessList;
@synthesize readAccessList = _readAccessList;
@synthesize editMode = _editMode;
@synthesize delegate = _delegate;
@synthesize inviteeLabel = _inviteeLabel;
@synthesize inviteContactsButton = _inviteContactsButton;
@synthesize scrollView = _scrollView;
@synthesize invitationView = _invitationView;
@synthesize charCountLabel = _charCountLabel;
@synthesize scratchMOC = _scratchMOC;

#define MAX_STORY_TITLE_LENGTH 40
#define TEXT_INSETS 5
#define VIEW_INSETS 8

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        // this should never be called directly.
        // initWithStory should be called instead
        NSAssert(false, @"Use initWithStory");
    }
    return self;
}

- (id) initWithStory:(Story *)story
{
    if (self = [super init]) {
        self.hidesBottomBarWhenPushed = YES;
        self.scratchMOC = [[RKManagedObjectStore defaultStore] newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType tracksChanges:YES];
        self.story = (Story *)[story cloneIntoNSManagedObjectContext:self.scratchMOC];
        if (self.story.remoteStatus == RemoteObjectStatusLocal) {
            self.editMode = ModifyStoryViewControllerEditModeAdd;
        } else {
            self.editMode = ModifyStoryViewControllerEditModeEdit;
        }
    }
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Modify Story"];
    [self.view endEditing:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)]];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];
    
    self.view.backgroundColor = BANYAN_WHITE_COLOR;
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.scrollEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
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
    self.storyTitleTextField.font = [UIFont fontWithName:@"Roboto-Bold" size:18];
    self.storyTitleTextField.returnKeyType = UIReturnKeyDone;
    [self.storyTitleTextField.layer setCornerRadius:8];
    [self.scrollView addSubview:self.storyTitleTextField];
    
    frame.origin.y = CGRectGetMaxY(self.storyTitleTextField.frame) + 2;
    frame.size.height = 12.0f;
    self.charCountLabel = [[UILabel alloc] initWithFrame:frame];
    self.charCountLabel.font = [UIFont fontWithName:@"Roboto" size:10];
    self.charCountLabel.textColor = BANYAN_GRAY_COLOR;
    self.charCountLabel.textAlignment = NSTextAlignmentRight;
    self.charCountLabel.hidden = YES;
    [self.scrollView addSubview:self.charCountLabel];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    [self.scrollView addGestureRecognizer:tapRecognizer];

    frame.origin.y = CGRectGetMaxY(self.charCountLabel.frame) + 30 /* distance between char count label and permission */;
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
    frame.size.height = 44.0f;
    self.inviteContactsButton.frame = frame;
    [self.invitationView addSubview:self.inviteContactsButton];
    
    // Default is selected permissions for writers
    self.writeAccessList = [BNPermissionsObject permissionsObject];

    // Default is limited permissions for viewers
    self.readAccessList = [BNPermissionsObject permissionsObject];
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    NSAssert(currentUser, @"No Current user available when modifying story");
    if (currentUser) {
        NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                        currentUser.name, @"name",
                                        currentUser.facebookId, @"id", nil];
        [self.readAccessList.inviteeList.allFacebookFriendsOf addObject:selfInvitation];
    }
    
    if (self.editMode == ModifyStoryViewControllerEditModeEdit) {
        // Set the title and permissions
        self.storyTitleTextField.text = self.story.title;
        // Contributors
        self.writeAccessList = self.story.writeAccess;
        // Viewers
        self.readAccessList = self.story.readAccess;
        
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
    InvitedTableViewController *invitedTableViewController = [[InvitedTableViewController alloc] initWithViewerPermissions:self.readAccessList
                                                                                                     contributorPermission:self.writeAccessList];
    invitedTableViewController.delegate = self;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:invitedTableViewController] animated:YES completion:nil];
}

// Update the story
- (IBAction)done:(UIBarButtonItem *)sender
{
    // If the story was already deleted while it was being edited in the view controller,
    // just inform the user and exit. Something more sophiticated might be needed later.
    if (self.story.isDeleted || self.story.hasBeenDeleted) {
        [[[UIAlertView alloc] initWithTitle:@"This story has been deleted"
                                    message:[NSString stringWithFormat:@"The story \"%@\" was deleted in the server and it can not be edited", self.story.title]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil]
         show];
        [self cancel:nil];
        return;
    }
    
    [self dismissKeyboard:nil];
    // Title
    self.story.title = (self.storyTitleTextField.text && ![self.storyTitleTextField.text isEqualToString:@""]) ? self.storyTitleTextField.text : [BNMisc shortCurrentDate];
    
    // Story Privacy
    BOOL samePermissions = YES;
    if (![self.writeAccessList isEqual:self.story.writeAccess]) {
        samePermissions = NO;
    }
    if (![self.readAccessList isEqual:self.story.readAccess]) {
        samePermissions = NO;
    }
    self.story.writeAccess = self.writeAccessList;
    self.story.readAccess = self.readAccessList;

    self.story = (Story *)[self.story cloneIntoNSManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];
    
    // Upload Story
    if (self.editMode == ModifyStoryViewControllerEditModeAdd) {
        [Story createNewStory:self.story];
        BNLogInfo(@"New story %@ saved", self.story);
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"create story: write"
                                               label:[self.writeAccessList typeOfInvitee]
                                               value:[self.writeAccessList countOfInvitee]];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"create story: read"
                                               label:[self.readAccessList typeOfInvitee]
                                               value:[self.readAccessList countOfInvitee]];
        
    } else if (self.editMode == ModifyStoryViewControllerEditModeEdit) {
        [Story editStory:self.story];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"User Interaction" action:@"edit story"
                                               label:@"changed permissions"
                                               value:[NSNumber numberWithBool:samePermissions]];
    } else {
        NSAssert(false, @"Not a valid edit mode");
    }
    
    [self dismissEditViewWithCompletionBlock:^{
        [self.delegate modifyStoryViewControllerDidSelectStory:self.story];
    }];
}

- (IBAction)cancel:(id)sender
{
    [self dismissKeyboard:nil];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                              delegate:self
                                     cancelButtonTitle:@"Cancel"
                                destructiveButtonTitle:@"Delete draft"
                                     otherButtonTitles:nil];

    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

# pragma mark Instance methods
- (void) updatePermissionTextInView
{
    NSString *writeAccessStr = [BNPermissionsObject shortFormattedPermissionObject:self.writeAccessList level:BNPermissionObjectInvitationLevelAll];
    NSString *readAccessStr = [BNPermissionsObject shortFormattedPermissionObject:self.readAccessList level:BNPermissionObjectInvitationLevelAll];
    
    NSString *permStr = [NSString stringWithFormat:@"%@ can contribute to this story.\r%@ can view this story.", writeAccessStr, readAccessStr];
    NSMutableAttributedString *labelStr =[[NSMutableAttributedString alloc] initWithString:@"Who can contribute or view the story?"
                                                                                attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                                                             NSForegroundColorAttributeName: [UIColor grayColor]}];
    
    [labelStr appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\r\r"
                                                                            attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:8]}]];
    
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:permStr
                                                                             attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:12]}];
    [attr setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:14]}
                  range:[permStr rangeOfString:writeAccessStr]];
    [attr setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:14]}
                  range:[permStr rangeOfString:[NSString stringWithFormat:@"\r%@", readAccessStr]]];

    [labelStr appendAttributedString:attr];
    [self.inviteeLabel setAttributedText:labelStr];

    CGSize expectedSize = [labelStr boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.inviteeLabel.frame)-2*TEXT_INSETS, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                             context:nil].size;
    
    CGRect frame = self.inviteeLabel.frame;
    frame.size.height = ceilf(expectedSize.height) + 2*TEXT_INSETS;
    self.inviteeLabel.frame = frame;
    
    frame = self.inviteContactsButton.frame;
    frame.origin.y = CGRectGetMaxY(self.inviteeLabel.frame);
    self.inviteContactsButton.frame = frame;
    
    frame = self.invitationView.frame;
    frame.size.height = CGRectGetHeight(self.inviteeLabel.frame) + CGRectGetHeight(self.inviteContactsButton.frame);
    self.invitationView.frame = frame;
    
    CGSize scrollSize = self.view.bounds.size;
    frame = [self.invitationView convertRect:self.invitationView.bounds toView:self.view];
    scrollSize.height = CGRectGetMaxY(frame) + CGRectGetMaxY(self.navigationController.navigationBar.frame);
    self.scrollView.contentSize = scrollSize;
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

- (void) updateCharCountWithLength:(NSUInteger)len
{
    self.charCountLabel.text = [NSString stringWithFormat:@"%d charachers left", MAX_STORY_TITLE_LENGTH-len];
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
    [self dismissViewControllerAnimated:YES completion:completionBlock];
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#undef TEXT_INSETS
#undef VIEW_INSETS

@end

@implementation ModifyStoryViewController (UIActionSheetDelegate)
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        //remove the original piece in case of local draft unsaved
        if (self.editMode == ModifyStoryViewControllerEditModeAdd || self.story.remoteStatus == RemoteObjectStatusLocal)
            [self.story remove];
        
        self.story = nil; // Just in case
        [self dismissEditViewWithCompletionBlock:^{
            if ([self.delegate respondsToSelector:@selector(modifyStoryViewControllerDidDismiss:)]) {
                [self.delegate modifyStoryViewControllerDidDismiss:self];
            }
        }];
    }
}
@end

@implementation ModifyStoryViewController (UITextFieldDelegate)

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.charCountLabel.hidden = NO;
    [self updateCharCountWithLength:self.storyTitleTextField.text.length];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.charCountLabel.hidden = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    BOOL retValue = newLength <= MAX_STORY_TITLE_LENGTH;
    if (retValue)
        [self updateCharCountWithLength:newLength];
    return retValue;
}

#undef MAX_STORY_TITLE_LENGTH
@end
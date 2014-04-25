//
//  InvitedTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 4/7/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "InvitedTableViewController.h"
#import "BanyanAppDelegate.h"
#import "InvitedFBFriendsViewController.h"
#import "User.h"
#import "MZFormSheetController.h"
#import "HelpInfoViewController.h"

@interface InvitedTableViewController () <InvitedFBFriendsViewControllerDelegate>

@property (nonatomic, strong) BNPermissionsObject<BNPermissionsObject> *viewerPermission;
@property (nonatomic, strong) BNPermissionsObject<BNPermissionsObject> *contributorPermission;
@property (nonatomic, strong) NSDictionary *selfInvitation;

@end

@implementation InvitedTableViewController
@synthesize viewerPermission = _viewerPermission;
@synthesize contributorPermission = _contributorPermission;
@synthesize selfInvitation = _selfInvitation;

typedef enum {
    InvitedTableViewSectionContributor,
    InvitedTableViewSectionViewer,
    InvitedTableViewSectionMax,
} InvitedTableViewSection;

typedef enum {
    InvitedTableViewContributorsRowPublic,
    InvitedTableViewContributorsRowSelectedFB,
    InvitedTableViewContributorsRowMax,
} InvitedTableViewContributorsRow;

typedef enum {
    InvitedTableViewViewersRowPublic,
    InvitedTableViewViewersRowLimitedFB,
    InvitedTableViewViewersRowSelectedFB,
    InvitedTableViewViewersRowMax,
} InvitedTableViewViewersRow;

// When initialized from storyboard
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        
    }
    return self;
}

- (id)initWithViewerPermissions:(BNPermissionsObject<BNPermissionsObject> *)viewerPermission
          contributorPermission:(BNPermissionsObject<BNPermissionsObject> *)contributorPermission
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        
        NSDictionary *copyViewerPermission =
        (__bridge NSDictionary *)(CFPropertyListCreateDeepCopy(kCFAllocatorDefault,
                                                               (__bridge CFPropertyListRef)(viewerPermission),
                                                               kCFPropertyListImmutable));
        NSDictionary *copyContributorPermission =
        (__bridge NSDictionary *)(CFPropertyListCreateDeepCopy(kCFAllocatorDefault,
                                                               (__bridge CFPropertyListRef)(contributorPermission),
                                                               kCFPropertyListImmutable));
        
        self.viewerPermission = (BNPermissionsObject<BNPermissionsObject> *)[BNDuckTypedObject duckTypedObjectWrappingDictionary:copyViewerPermission];
        self.contributorPermission = (BNPermissionsObject<BNPermissionsObject> *)[BNDuckTypedObject duckTypedObjectWrappingDictionary:copyContributorPermission];
        
        self.title = @"Permissions for story";
        
        BNSharedUser *currentUser = [BNSharedUser currentUser];
        NSAssert(currentUser, @"No Current user available when modifying story");
        self.selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                               currentUser.name, @"name",
                               currentUser.facebookId, @"id", nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneInviting:)]];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];
    
    NSAttributedString *titleString = nil;
    titleString = [[NSAttributedString alloc] initWithString:@"Permissions for story"
                                                  attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:16],
                                                               NSForegroundColorAttributeName: BANYAN_DARKGRAY_COLOR}];
    NSAttributedString *tapString = [[NSAttributedString alloc] initWithString:@"\rtap for more information"
                                                                    attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:10],
                                                                                 NSForegroundColorAttributeName: BANYAN_GRAY_COLOR}];
    
    NSMutableAttributedString *tapAttrString = [[NSMutableAttributedString alloc] initWithAttributedString:titleString];
    [tapAttrString appendAttributedString:tapString];
    UIButton *titleButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [titleButton setAttributedTitle:tapAttrString forState:UIControlStateNormal];
    titleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    titleButton.titleLabel.numberOfLines = 2;
    [titleButton addTarget:self action:@selector(showExplanation:) forControlEvents:UIControlEventTouchUpInside];
    [titleButton sizeToFit];
    self.navigationItem.titleView = titleButton;
    
//    self.tableView.rowHeight = 75.0f;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Invitation screen"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *firstTimeDict = [[defaults dictionaryForKey:BNUserDefaultsFirstTimeActionsDict] mutableCopy];
    if (![firstTimeDict objectForKey:BNUserDefaultsFirstTimeSettingPermissions]) {
        [firstTimeDict setObject:[NSNumber numberWithBool:YES] forKey:BNUserDefaultsFirstTimeSettingPermissions];
        [defaults setObject:firstTimeDict forKey:BNUserDefaultsFirstTimeActionsDict];
        [defaults synchronize];
        [self showExplanation:nil];
    }
}

- (IBAction)showExplanation:(id)sender
{
#define MZFORMSHEET_TOP_INSET 40.0
#define MZFORMSHEET_LEFT_INSET 20.0
    
    HelpInfoViewController *vc = [[HelpInfoViewController alloc] initWithNibName:@"HelpInfoViewController" bundle:nil];
    MZFormSheetController *formSheet = [[MZFormSheetController alloc] initWithViewController:vc];
    formSheet.transitionStyle = MZFormSheetTransitionStyleSlideFromTop;
    formSheet.portraitTopInset = MZFORMSHEET_TOP_INSET;
    formSheet.landscapeTopInset = MZFORMSHEET_LEFT_INSET;
    formSheet.presentedFormSheetSize = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds) - 2*MZFORMSHEET_LEFT_INSET,
                                                  CGRectGetHeight([UIScreen mainScreen].bounds) - 2*MZFORMSHEET_TOP_INSET);
    formSheet.willPresentCompletionHandler = ^(UIViewController *presentedFSViewController) {
        // Passing data
        __weak typeof(self) wself = self;
        HelpInfoViewController *helpInfoVc = (HelpInfoViewController *)presentedFSViewController;
        helpInfoVc.descriptionLabel.attributedText = [wself helpText];
    };
    
    [self mz_presentFormSheetController:formSheet animated:YES completionHandler:^(MZFormSheetController *formSheetController) {
    }];
#undef MZFORMSHEET_TOP_INSET
#undef MZFORMSHEET_LEFT_INSET
}

- (NSAttributedString *)helpText
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentJustified;
    
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:@"\rInvitations Control Center\r\r"
                                                                                    attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:14],
                                                                                                 NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                                 NSParagraphStyleAttributeName: paragraphStyle,
                                                                                                 NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    NSMutableAttributedString *info1 = [[NSMutableAttributedString alloc] initWithString:@"These settings allow you to control who can contribute to this story and who can read this story.\r\r"
                                                                attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:12],
                                                                             NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                             NSParagraphStyleAttributeName: paragraphStyle,
                                                                             NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];


    NSMutableAttributedString *info2 = [[NSMutableAttributedString alloc] initWithString:@"By default, the permissions are set such that only you can contribute to the story, and anyone in the list of your Facebook friends can read the story. "
                                                                              attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:12],
                                                                                           NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                           NSParagraphStyleAttributeName: paragraphStyle,
                                                                                           NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    
    NSMutableAttributedString *info3 = [[NSMutableAttributedString alloc] initWithString:@"You can change it by choosing selected individuals who can contribute to or read this story, or select Public if you want anyone to contribute to or read this story.\r\r"
                                        "Currently we only allow individuals to be selected as a contributor or viewer from the list of your Facebook friends. If you would like people from other walks you would like to add, let us know through the Feedback tab on the home screen menu.\r\r"
                                                                              attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:12],
                                                                                           NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                           NSParagraphStyleAttributeName: paragraphStyle,
                                                                                           NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    
    NSMutableAttributedString *info4 = [[NSMutableAttributedString alloc] initWithString:@"When you add a contributor to a story, you are also implicitly providing her/him the permission to invite other contributors or viewers from their network.\r"
                                                                              attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto-Bold" size:12],
                                                                                           NSForegroundColorAttributeName: BANYAN_BLACK_COLOR,
                                                                                           NSParagraphStyleAttributeName: paragraphStyle,
                                                                                           NSBaselineOffsetAttributeName : [NSNumber numberWithInt:0]}];
    
    [title appendAttributedString:info1];
    [title appendAttributedString:info2];
    [title appendAttributedString:info3];
    [title appendAttributedString:info4];
    
    return title;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return InvitedTableViewSectionMax;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
#define DEFAULT_CELL_HEIGHT 45.0
#define DEFAULT_SIZE_PER_TEXT_LINE 14.0
    CGFloat extraRowHeight = 0.0;
    
    switch (indexPath.section) {
        case InvitedTableViewSectionContributor:
            switch (indexPath.row) {
                case InvitedTableViewContributorsRowPublic:
                    break;
                case InvitedTableViewContributorsRowSelectedFB:
                    extraRowHeight = self.contributorPermission.inviteeList.facebookFriends.count * DEFAULT_SIZE_PER_TEXT_LINE;
                    break;
                    
                default:
                    break;
            }
            break;
            
        case InvitedTableViewSectionViewer:
            switch (indexPath.row) {
                case InvitedTableViewViewersRowPublic:
                    break;
                    
                case InvitedTableViewViewersRowLimitedFB:
                    extraRowHeight = self.viewerPermission.inviteeList.allFacebookFriendsOf.count * DEFAULT_SIZE_PER_TEXT_LINE;
                    break;
                    
                case InvitedTableViewViewersRowSelectedFB:
                    extraRowHeight = self.viewerPermission.inviteeList.facebookFriends.count * DEFAULT_SIZE_PER_TEXT_LINE;
                    break;
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    
    // 2009 value below is because of a note in the documentation:
    // Important: Due to an underlying implementation detail, you should not return values greater than 2009.
    return MIN(DEFAULT_CELL_HEIGHT + extraRowHeight, 2009);
#undef DEFAULT_CELL_HEIGHT
#undef DEFAULT_SIZE_PER_TEXT_LINE
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case InvitedTableViewSectionContributor: // Contributor Permission Section
            return InvitedTableViewContributorsRowMax;
            break;
            
        case InvitedTableViewSectionViewer: // Reader Permission Section
            return InvitedTableViewViewersRowMax;
            break;
            
        default:
            break;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case InvitedTableViewSectionContributor:
            return @"Contributors";
            break;
            
        case InvitedTableViewSectionViewer:
            return @"Viewers";
            break;
            
        default:
            return nil;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    switch (indexPath.section) {
        case InvitedTableViewSectionContributor:
            switch (indexPath.row) {
                case InvitedTableViewContributorsRowPublic:
                    cell.textLabel.text = @"Public";
                    cell.detailTextLabel.text = [BNPermissionsObject longFormattedPermissionObject:self.contributorPermission level:BNPermissionObjectInvitationLevelPublic list:YES];
                    if ([self.contributorPermission.inviteeList.isPublic boolValue]) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    break;
                case InvitedTableViewContributorsRowSelectedFB:
                    cell.textLabel.text = @"Selected Facebook friends";
                    cell.detailTextLabel.text = [BNPermissionsObject longFormattedPermissionObject:self.contributorPermission level:BNPermissionObjectInvitationLevelSelectedFacebookFriends list:YES];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                    
                default:
                    break;
            }
            break;
            
        case InvitedTableViewSectionViewer:
            switch (indexPath.row) {
                case InvitedTableViewViewersRowPublic:
                    cell.textLabel.text = @"Public";
                    cell.detailTextLabel.text = [BNPermissionsObject longFormattedPermissionObject:self.viewerPermission level:BNPermissionObjectInvitationLevelPublic list:YES];
                    if ([self.viewerPermission.inviteeList.isPublic boolValue]) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    break;
                    
                case InvitedTableViewViewersRowLimitedFB:
                    cell.textLabel.text = @"All friends on Facebook";
                    cell.detailTextLabel.text = [BNPermissionsObject longFormattedPermissionObject:self.viewerPermission level:BNPermissionObjectInvitationLevelFacebookFriendsOf list:YES];
                    if ([self.viewerPermission.inviteeList.allFacebookFriendsOf containsObject:self.selfInvitation]) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    break;
                    
                case InvitedTableViewViewersRowSelectedFB:
                    cell.textLabel.text = @"Selected Facebook friends";
                    cell.detailTextLabel.text = [BNPermissionsObject longFormattedPermissionObject:self.viewerPermission level:BNPermissionObjectInvitationLevelSelectedFacebookFriends list:YES];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    cell.textLabel.font = [UIFont fontWithName:@"Roboto-Medium" size:20];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Roboto" size:12];
    cell.detailTextLabel.textColor = BANYAN_GRAY_COLOR;
    cell.detailTextLabel.numberOfLines = 0;

    // Disable view permissions button if contributor permissions is Public
    if ([self.contributorPermission.inviteeList.isPublic boolValue] && indexPath.section == InvitedTableViewSectionViewer) {
        cell.contentView.alpha = 0.5;
    } else {
        cell.contentView.alpha = 1.0;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Disable view permissions button if contributor permissions is Public
    if ([self.contributorPermission.inviteeList.isPublic boolValue] && indexPath.section == InvitedTableViewSectionViewer) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    InvitedFBFriendsViewController *vc = nil;
    
    switch (indexPath.section) {
        case InvitedTableViewSectionContributor:
            switch (indexPath.row) {
                case InvitedTableViewContributorsRowPublic:
                    self.contributorPermission.inviteeList.isPublic = [NSNumber numberWithBool:!([self.contributorPermission.inviteeList.isPublic boolValue])];
                    if ([self.contributorPermission.inviteeList.isPublic boolValue]) {
                        self.viewerPermission.inviteeList.isPublic = [NSNumber numberWithBool:YES];
                    }
                    break;
                    
                case InvitedTableViewContributorsRowSelectedFB:
                    vc = [[InvitedFBFriendsViewController alloc] initWithViewerPermissions:self.viewerPermission contributorPermission:self.contributorPermission];
                    vc.delegate = self;
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case InvitedTableViewSectionViewer:
            switch (indexPath.row) {
                case InvitedTableViewViewersRowPublic:
                    self.viewerPermission.inviteeList.isPublic  = [NSNumber numberWithBool:![self.viewerPermission.inviteeList.isPublic boolValue]];
                    break;
                    
                case InvitedTableViewViewersRowLimitedFB:
                    if (![self.viewerPermission.inviteeList.allFacebookFriendsOf containsObject:self.selfInvitation])
                        [self.viewerPermission.inviteeList.allFacebookFriendsOf addObject:self.selfInvitation];
                    else
                        [self.viewerPermission.inviteeList.allFacebookFriendsOf removeObject:self.selfInvitation];
                    break;
                    
                case InvitedTableViewViewersRowSelectedFB:
                    vc = [[InvitedFBFriendsViewController alloc] initWithViewerPermissions:self.viewerPermission
                                                                     contributorPermission:self.contributorPermission];
                    vc.delegate = self;
                    [self.navigationController pushViewController:vc animated:YES];
                    break;
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    [tableView reloadData];
}

# pragma mark target-actions
- (IBAction)doneInviting:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.delegate invitedTableViewController:self
             finishedInvitingForViewerPermissions:self.viewerPermission
                           contributorPermissions:self.contributorPermission];
    }];
}

- (IBAction)cancel:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark InvitedFBFriendsViewControllerDelegate
- (void) invitedFBFriendsViewController:(InvitedFBFriendsViewController *)invitedFBFriendsViewController
             finishedInvitingForViewers:(NSMutableArray *)selectedViewers
                           contributors:(NSMutableArray *)selectedContributors
{
    // Add the names of contributors to viewing as well
    for (NSDictionary *friend in selectedContributors) {
        if (![selectedViewers containsObject:friend]) {
            [selectedViewers addObject:friend];
        }
    }
    self.viewerPermission.inviteeList.facebookFriends = selectedViewers;
    self.contributorPermission.inviteeList.facebookFriends = selectedContributors;
    [self.tableView reloadData];
}

@end


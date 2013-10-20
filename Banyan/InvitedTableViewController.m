//
//  InvitedTableViewController.m
//  Storied
//
//  Created by Devang Mundhra on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InvitedTableViewController.h"
#import "BanyanAppDelegate.h"
#import "InvitedFBFriendsViewController.h"
#import "User.h"

@interface InvitedTableViewController () <InvitedFBFriendsViewControllerDelegate>

@property (nonatomic, strong) BNPermissionsObject *viewerPermission;
@property (nonatomic, strong) BNPermissionsObject *contributorPermission;

@end

@implementation InvitedTableViewController
@synthesize viewerPermission = _viewerPermission;
@synthesize contributorPermission = _contributorPermission;

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

- (id)initWithViewerPermissions:(BNPermissionsObject *)viewerPermission contributorPermission:(BNPermissionsObject *)contributorPermission
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        
        _viewerPermission = viewerPermission;
        _contributorPermission = contributorPermission;
        
        self.title = @"Permissions for story";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneInviting:)]];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]];
    
//    self.tableView.rowHeight = 75.0f;
    [TestFlight passCheckpoint:@"Invitation view loaded"];
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
            return @"Permission for contributors";
            break;
            
        case InvitedTableViewSectionViewer:
            return @"Permission for viewers";
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
                    if ([self.contributorPermission.scope isEqualToString:kBNStoryPrivacyScopePublic]) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        cell.detailTextLabel.text = [self.contributorPermission stringifyPermissionObject];
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                        cell.detailTextLabel.text = @"";
                    }
                    break;
                case InvitedTableViewContributorsRowSelectedFB:
                    cell.textLabel.text = @"Selected Facebook friends";
                    if ([self.contributorPermission.scope isEqualToString:kBNStoryPrivacyScopeInvited]) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        cell.detailTextLabel.text = [self.contributorPermission stringifyPermissionObject];
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        cell.detailTextLabel.text = @"";
                    }
                    break;
                    
                default:
                    break;
            }
            break;
            
        case InvitedTableViewSectionViewer:
            switch (indexPath.row) {
                case InvitedTableViewViewersRowPublic:
                    cell.textLabel.text = @"Public";
                    if ([self.viewerPermission.scope isEqualToString:kBNStoryPrivacyScopePublic]) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        cell.detailTextLabel.text = [self.viewerPermission stringifyPermissionObject];
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                        cell.detailTextLabel.text = @"";
                    }
                    break;
                    
                case InvitedTableViewViewersRowLimitedFB:
                    cell.textLabel.text = @"All friends on Facebook";
                    if ([self.viewerPermission.scope isEqualToString:kBNStoryPrivacyScopeLimited]) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        cell.detailTextLabel.text = [self.viewerPermission stringifyPermissionObject];
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                        cell.detailTextLabel.text = @"";
                    }
                    break;
                    
                case InvitedTableViewViewersRowSelectedFB:
                    cell.textLabel.text = @"Selected Facebook friends";
                    if ([self.viewerPermission.scope isEqualToString:kBNStoryPrivacyScopeInvited]) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                        cell.detailTextLabel.text = [self.viewerPermission stringifyPermissionObject];
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        cell.detailTextLabel.text = @"";
                    }
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
    
    // Disable view permissions button if contributor permissions is Public
    if ([self.contributorPermission.scope isEqualToString:kBNStoryPrivacyScopePublic] && indexPath.section == InvitedTableViewSectionViewer) {
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
    if ([self.contributorPermission.scope isEqualToString:kBNStoryPrivacyScopePublic] && indexPath.section == InvitedTableViewSectionViewer) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    InvitedFBFriendsViewController *vc = nil;
    BNSharedUser *currentUser = nil;
    NSDictionary *selfInvitation = nil;
    NSMutableArray *fbInvitees = nil;
    
    switch (indexPath.section) {
        case InvitedTableViewSectionContributor:
            switch (indexPath.row) {
                case InvitedTableViewContributorsRowPublic:
                    self.contributorPermission.scope = kBNStoryPrivacyScopePublic;
                    self.viewerPermission.scope = kBNStoryPrivacyScopePublic;
                    break;
                    
                case InvitedTableViewContributorsRowSelectedFB:
                    self.contributorPermission.scope = kBNStoryPrivacyScopeInvited;
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
                    self.viewerPermission.scope = kBNStoryPrivacyScopePublic;
                    break;
                    
                case InvitedTableViewViewersRowLimitedFB:
                    self.viewerPermission.scope = kBNStoryPrivacyScopeLimited;
                    currentUser = [BNSharedUser currentUser];
                    if (HAVE_ASSERTS)
                        NSAssert(currentUser, @"No Current user available when modifying story");
                    if (currentUser) {
                        selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    currentUser.name, @"name",
                                                    currentUser.facebookId, @"id", nil];
                        fbInvitees = self.viewerPermission.facebookInvitedList;
                        
                        if (![fbInvitees containsObject:selfInvitation])
                            [fbInvitees addObject:selfInvitation];
                        self.viewerPermission.facebookInvitedList = fbInvitees;
                    }

                    break;
                    
                case InvitedTableViewViewersRowSelectedFB:
                    self.viewerPermission.scope = kBNStoryPrivacyScopeInvited;
                    // Remove the self invitation from the list if here
                    currentUser = [BNSharedUser currentUser];
                    if (HAVE_ASSERTS)
                        NSAssert(currentUser, @"No Current user available when modifying story");
                    if (currentUser) {
                        selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                          currentUser.name, @"name",
                                          currentUser.facebookId, @"id", nil];
                        fbInvitees = self.viewerPermission.facebookInvitedList;
                        
                        [fbInvitees removeObject:selfInvitation];
                        self.viewerPermission.facebookInvitedList = fbInvitees;
                    }
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
    if ([self.viewerPermission.scope isEqualToString:kBNStoryPrivacyScopeLimited]) {
        BNSharedUser *currentUser = [BNSharedUser currentUser];
        if (HAVE_ASSERTS)
            NSAssert(currentUser, @"No Current user available when modifying story");
        if (currentUser) {
            NSDictionary *selfInvitation = [NSDictionary dictionaryWithObjectsAndKeys:
                                            currentUser.name, @"name",
                                            currentUser.facebookId, @"id", nil];
            if (![selectedViewers containsObject:selfInvitation])
                [selectedViewers addObject:selfInvitation];
            
        }
    }
    self.viewerPermission.facebookInvitedList = selectedViewers;
    self.contributorPermission.facebookInvitedList = selectedContributors;
    [self.tableView reloadData];
}

@end


//
//  SettingsTableViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/1/12.
//
//

#import "SettingsTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "User.h"
#import "BNAWSSNSClient.h"
#import "UIViewController+BNSlidingViewControllerAdditions.h"

@interface SettingsTableViewController ()

@end

typedef enum {
//    SettingsTableViewReadingOptionsSection,
    SettingsTableViewNotificationsSection,
    SettingsTableViewSectionMax,
} SettingsTableViewSection;

typedef enum {
    SettingsReadingOptionsPieceChangeTransition = 0,
    SettingsReadingOptionsSectionsMax,
} SettingsReadingOptionsSections;

typedef enum {
    SettingsNotificationSectionAddStoryContribute = 0,
    SettingsNotificationSectionAddStoryView,
    SettingsNotificationSectionAddPiece,
    SettingsNotificationSectionPieceAction,
//    SettingsNotificationSectionUserFollowing,
    SettingsNotificationsSectionMax,
} SettingsNotificationsSection;

@implementation SettingsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"Settings";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.clearsSelectionOnViewWillAppear = YES;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self prepareForSlidingViewController];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setGAIScreenName:@"Settings screen"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (![BanyanAppDelegate loggedIn])
        return 1;
    else
        return SettingsTableViewSectionMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
//        case SettingsTableViewReadingOptionsSection:
//            return SettingsReadingOptionsSectionsMax;
//            break;
            
        case SettingsTableViewNotificationsSection:
            return SettingsNotificationsSectionMax;
            break;

        default:
            return 0;
            break;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
//        case SettingsTableViewReadingOptionsSection:
//            return @"Reading Options";
//            break;
            
        case SettingsTableViewNotificationsSection:
            return @"Notifications";
            break;
            
        default:
            return nil;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Settings Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:15];
    
    // Configure the cell...
    switch (indexPath.section) {
//        case SettingsTableViewReadingOptionsSection:
//            cell.textLabel.text = [self textForReadingOptionsSectionAtRow:indexPath.row];
//            cell.accessoryView = [self accessoryViewForReadingOptionsSectionAtRow:indexPath.row];
//            break;
            
        case SettingsTableViewNotificationsSection:
            cell.textLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:12];
            cell.textLabel.text = [self textForNotificationsSectionAtRow:indexPath.row];
            cell.accessoryView = [self accessoryViewForNotificationsSectionAtRow:indexPath.row];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
            
        default:
            cell.textLabel.text = @"Undefined";
            break;
    }
    cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // Navigation logic may go here. Create and push another view controller.
    
    switch (indexPath.section) {
//        case SettingsTableViewReadingOptionsSection:
//            [self actionForReadingOptionsSectionAtRow:indexPath.row];
//            break;

        case SettingsTableViewNotificationsSection:
            [self actionForNotificationsSectionAtRow:indexPath.row];
            break;
            
        default:
            break;
    }
}

# pragma mark Reading Options Section

- (NSString *) textForReadingOptionsSectionAtRow:(NSInteger)row
{
    switch (row) {
        case SettingsReadingOptionsPieceChangeTransition:
            return @"Page Turn Animation";
            break;
            
        default:
            assert(false);
            break;
    }
}

- (void) actionForReadingOptionsSectionAtRow:(NSInteger) row
{
    switch (row) {
            
        default:
            break;
    }
}

- (UIView *)accessoryViewForReadingOptionsSectionAtRow:(NSInteger) row
{
    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL on;
    switch (row) {
        case SettingsReadingOptionsPieceChangeTransition:
            [switchView addTarget:self action:@selector(pageTurnAnimationSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            on = [defaults boolForKey:BNUserDefaultsUserPageTurnAnimation];
            break;
            
        default:
            assert(false);
            break;
    }
    [switchView setOn:on animated:NO];
    return switchView;
}

- (IBAction)pageTurnAnimationSwitchChanged:(UISwitch *)switchControl
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:switchControl.on forKey:BNUserDefaultsUserPageTurnAnimation];
    [defaults synchronize];

    BNLogInfo( @"The %@: %@", BNUserDefaultsUserPageTurnAnimation, switchControl.on ? @"ON" : @"OFF" );
}

# pragma mark Notifications Section
- (NSString *) textForNotificationsSectionAtRow:(NSInteger)row
{
    switch (row) {
        case SettingsNotificationSectionAddStoryContribute:
            return @"Invited as a contributor to a story";
            break;
        case SettingsNotificationSectionAddStoryView:
            return @"Added as a spectator in a story";
            break;
        case SettingsNotificationSectionAddPiece:
            return @"Story I follow has a piece added";
            break;
        case SettingsNotificationSectionPieceAction:
            return @"Piece I added is liked";
            break;
//        case SettingsNotificationSectionUserFollowing:
//            return @"User starts following my stories";
//            break;
            
        default:
            assert(false);
            break;
    }
}

- (void) actionForNotificationsSectionAtRow:(NSInteger) row
{
    switch (row) {
            
        default:
            break;
    }
}

- (UIView *)accessoryViewForNotificationsSectionAtRow:(NSInteger) row
{
    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL on;
    switch (row) {
        case SettingsNotificationSectionAddStoryContribute:
            [switchView addTarget:self action:@selector(addStoryContribNotificationsSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            on = [defaults boolForKey:BNUserDefaultsAddStoryInvitedContributePushNotification];
            break;
        case SettingsNotificationSectionAddStoryView:
            [switchView addTarget:self action:@selector(addStoryViewNotificationsSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            on = [defaults boolForKey:BNUserDefaultsAddStoryInvitedViewPushNotification];
            break;
        case SettingsNotificationSectionAddPiece:
            [switchView addTarget:self action:@selector(addPieceNotificationsSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            on = [defaults boolForKey:BNUserDefaultsAddPieceToContributedStoryPushNotification];
            break;
        case SettingsNotificationSectionPieceAction:
            [switchView addTarget:self action:@selector(pieceActionNotificationsSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            on = [defaults boolForKey:BNUserDefaultsPieceActionPushNotification];
            break;
//        case SettingsNotificationSectionUserFollowing:
//            [switchView addTarget:self action:@selector(userFollowNotificationsSwitchChanged:) forControlEvents:UIControlEventValueChanged];
//            on = [defaults boolForKey:BNUserDefaultsUserFollowingPushNotification];
//            break;
            
        default:
            assert(false);
            break;
    }
    [switchView setOn:on animated:NO];
    return switchView;
}

- (IBAction)addStoryContribNotificationsSwitchChanged:(UISwitch *)switchControl
{
    BOOL isEnabled = switchControl.on;
    void (^snsNotificationCompletionBlock)(bool, NSError *) = ^(bool succeeded, NSError *error) {
        if (succeeded) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:isEnabled forKey:BNUserDefaultsAddStoryInvitedContributePushNotification];
            [defaults synchronize];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error in updating notification settings"
                                            message:@"There was an error in updating your notification preference. We are currently looking into it.\rPlease try again in sometime."
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
        }
    };

    if (switchControl.on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_INVTOCONTRIBUTE forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:@"InvitedToContribute"] inBackgroundWithBlock:snsNotificationCompletionBlock];
    } else {
        [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_INVTOCONTRIBUTE forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:@"InvitedToContribute"] inBackgroundWithBlock:snsNotificationCompletionBlock];
    }
    BNLogInfo( @"The %@: %@", BNAddStoryInvitedContributePushNotification, switchControl.on ? @"ON" : @"OFF" );
}
- (IBAction)addStoryViewNotificationsSwitchChanged:(UISwitch *)switchControl
{
    BOOL isEnabled = switchControl.on;
    void (^snsNotificationCompletionBlock)(bool, NSError *) = ^(bool succeeded, NSError *error) {
        if (succeeded) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:isEnabled forKey:BNUserDefaultsAddStoryInvitedViewPushNotification];
            [defaults synchronize];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error in updating notification settings"
                                            message:@"There was an error in updating your notification preference. We are currently looking into it.\rPlease try again in sometime."
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
        }
    };
    
    if (switchControl.on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_INVTOVIEW forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:@"InvitedToView"] inBackgroundWithBlock:snsNotificationCompletionBlock];
    } else {
        [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_INVTOVIEW forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:@"InvitedToView"] inBackgroundWithBlock:snsNotificationCompletionBlock];
    }
    BNLogInfo( @"The %@: %@", BNAddStoryInvitedViewPushNotification, switchControl.on ? @"ON" : @"OFF" );
}
- (IBAction)addPieceNotificationsSwitchChanged:(UISwitch *)switchControl
{
    BOOL isEnabled = switchControl.on;
    void (^snsNotificationCompletionBlock)(bool, NSError *) = ^(bool succeeded, NSError *error) {
        if (succeeded) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:isEnabled forKey:BNUserDefaultsAddPieceToContributedStoryPushNotification];
            [defaults synchronize];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error in updating notification settings"
                                            message:@"There was an error in updating your notification preference. We are currently looking into it.\rPlease try again in sometime."
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
        }
    };
    
    if (switchControl.on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_PIECEADDED forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:@"PieceAdded"] inBackgroundWithBlock:snsNotificationCompletionBlock];
    } else {
        [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_PIECEADDED forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:@"PieceAdded"] inBackgroundWithBlock:snsNotificationCompletionBlock];
    }
    BNLogInfo( @"The %@: %@", BNAddPieceToContributedStoryPushNotification, switchControl.on ? @"ON" : @"OFF" );
}
- (IBAction)pieceActionNotificationsSwitchChanged:(UISwitch *)switchControl
{
    BOOL isEnabled = switchControl.on;
    void (^snsNotificationCompletionBlock)(bool, NSError *) = ^(bool succeeded, NSError *error) {
        if (succeeded) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:isEnabled forKey:BNUserDefaultsPieceActionPushNotification];
            [defaults synchronize];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error in updating notification settings"
                                            message:@"There was an error in updating your notification preference. We are currently looking into it.\rPlease try again in sometime."
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
        }
    };
    
    if (switchControl.on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_PIECEACTION forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:@"PieceAction"] inBackgroundWithBlock:snsNotificationCompletionBlock];
    } else {
        [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_PIECEACTION forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:@"PieceAction"] inBackgroundWithBlock:snsNotificationCompletionBlock];
    }
    BNLogInfo( @"The %@: %@", BNPieceActionPushNotification, switchControl.on ? @"ON" : @"OFF" );
}
- (IBAction)userFollowNotificationsSwitchChanged:(UISwitch *)switchControl
{
    BOOL isEnabled = switchControl.on;
    void (^snsNotificationCompletionBlock)(bool, NSError *) = ^(bool succeeded, NSError *error) {
        if (succeeded) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:isEnabled forKey:BNUserDefaultsUserFollowingPushNotification];
            [defaults synchronize];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error in updating notification settings"
                                            message:@"There was an error in updating your notification preference. We are currently looking into it.\rPlease try again in sometime."
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
        }
    };
    
    if (switchControl.on) {
        [BNAWSSNSClient enableNotificationsFromChannel:AWS_APPARN_USERFOLLOWING forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:@"UserFollowing"] inBackgroundWithBlock:snsNotificationCompletionBlock];
    } else {
        [BNAWSSNSClient disableNotificationsFromChannel:AWS_APPARN_USERFOLLOWING forEndpointArn:[[BNAWSSNSClient endpointsDict] objectForKey:@"UserFollowing"] inBackgroundWithBlock:snsNotificationCompletionBlock];
    }
    BNLogInfo( @"The %@: %@", BNUserFollowingPushNotification, switchControl.on ? @"ON" : @"OFF" );
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

@end

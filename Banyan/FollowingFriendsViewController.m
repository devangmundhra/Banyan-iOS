//
//  FollowingFriendsViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/2/12.
//
//

#import "FollowingFriendsViewController.h"
#import "Activity+Create.h"
#import <QuartzCore/QuartzCore.h>
#import "User.h"
#import "UIViewController+BNSlidingViewControllerAdditions.h"

@interface FollowingFriendsViewController ()

@end

@implementation FollowingFriendsViewController

@synthesize dataSource = _dataSource;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"Follow/Find Friends";
        
        // Get friends being followed
        NSArray *facebookFriendsOnBanyan = [[NSUserDefaults standardUserDefaults] arrayForKey:BNUserDefaultsBanyanUsersFacebookFriends];
        NSSortDescriptor *followingSortDescriptor =[NSSortDescriptor sortDescriptorWithKey:@"userBeingFollowed" ascending:NO];
        NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *sortArray = [NSArray arrayWithObjects:followingSortDescriptor, nameSortDescriptor, nil];
        NSArray *sortedFriendsOnBanyan = [facebookFriendsOnBanyan sortedArrayUsingDescriptors:sortArray];
        self.dataSource = sortedFriendsOnBanyan;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add the find friends button
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 45)];
    UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [actionButton.titleLabel setFont:[UIFont fontWithName:@"Roboto-Bold" size:18]];
    actionButton.userInteractionEnabled = YES;
    CGRect frame = view.frame;
    CALayer *layer = actionButton.layer;
    [layer setCornerRadius:5.0f];
    [layer setMasksToBounds:YES];
    [layer setBorderWidth: 1.0f];
    [actionButton setTitle:@"Find Friends" forState:UIControlStateNormal];
    [actionButton setBackgroundColor:BANYAN_GREEN_COLOR];
    [actionButton addTarget:self action:@selector(findFriends) forControlEvents:UIControlEventTouchUpInside];
    actionButton.enabled = NO;
    layer.borderColor = BANYAN_DARK_GREEN_COLOR.CGColor;
    frame.origin.x += 20;
    frame.origin.y += 10;
    frame.size.width -= 40;
    frame.size.height = 30;
    actionButton.frame = frame;
    self.tableView.tableHeaderView = view;
    [view addSubview:actionButton];
    [self prepareForSlidingViewController];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FollowingFriendsCell";
    FollowingUsersCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[FollowingUsersCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setDelegate:self];
    }
    // Configure the cell...
    [cell setUser:[self.dataSource objectAtIndex:indexPath.row]];
    cell.followButton.selected = [[cell.user objectForKey:@"userBeingFollowed"] boolValue];
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.dataSource.count) {
        return [FollowingUsersCell heightForCell];
    } else {
        return 44.0f;
    }
}

#pragma mark - PAPFindFriendsCellDelegate

- (void)cell:(FollowingUsersCell *)cellView didTapUserButton:(NSDictionary *)aUser {
    // Push account view controller
//    AccountViewController *accountViewController = [[AccountViewController alloc] initWithStyle:UITableViewStylePlain];
//    [accountViewController setUser:aUser];
//    [self.navigationController pushViewController:accountViewController animated:YES];
}

- (void)cell:(FollowingUsersCell *)cellView didTapFollowButton:(NSDictionary *)aUser {
    [self shouldToggleFollowFriendForCell:cellView];
}


#pragma mark target - actions

- (void)shouldToggleFollowFriendForCell:(FollowingUsersCell *)cell {
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    NSMutableDictionary *cellUser = cell.user;
    if ([cell.followButton isSelected]) {
        // Unfollow
        cell.followButton.selected = NO;
        Activity *activity = [Activity activityWithType:kBNActivityTypeUnfollowUser
                                                      fromUser:currentUser.resourceUri
                                                        toUser:[cellUser objectForKey:@"objectId"]
                                                       piece:nil
                                                       story:nil];
        [Activity createActivity:activity];
        [self changeFollowingStatusForUser:cellUser toStatus:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:BNUserFollowingChangedNotification object:nil];
    } else {
        // Follow
        cell.followButton.selected = YES;
        Activity *activity = [Activity activityWithType:kBNActivityTypeFollowUser
                                               fromUser:currentUser.resourceUri
                                                 toUser:[cellUser objectForKey:@"objectId"]
                                                piece:nil
                                                story:nil];
        [Activity createActivity:activity];
        [self changeFollowingStatusForUser:cellUser toStatus:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:BNUserFollowingChangedNotification object:nil];
    }
}

- (void) changeFollowingStatusForUser:(NSMutableDictionary *)user toStatus:(BOOL) status
{
    NSMutableArray *facebookFriendsOnBanyan = [[[NSUserDefaults standardUserDefaults]
                                                objectForKey:BNUserDefaultsBanyanUsersFacebookFriends] mutableCopy];
    NSMutableDictionary *newCellUser = [user mutableCopy];
    // This is needed since for matching, the USER_BEING_FOLLOWED in both the array and "user" should be same
    [newCellUser setObject:[NSNumber numberWithBool:!status] forKey:@"userBeingFollowed"];
    NSUInteger index = [facebookFriendsOnBanyan indexOfObject:newCellUser];
    [newCellUser setObject:[NSNumber numberWithBool:status] forKey:@"userBeingFollowed"];
    [facebookFriendsOnBanyan replaceObjectAtIndex:index withObject:newCellUser];
    [[NSUserDefaults standardUserDefaults] setObject:facebookFriendsOnBanyan forKey:BNUserDefaultsBanyanUsersFacebookFriends];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) findFriends
{
    NSLog(@"Finding Friends");
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end

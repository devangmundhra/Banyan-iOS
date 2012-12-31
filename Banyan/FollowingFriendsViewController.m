//
//  FollowingFriendsViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 9/2/12.
//
//

#import "FollowingFriendsViewController.h"
#import "AFParseAPIClient.h"
#import "User_Defines.h"

@interface FollowingFriendsViewController ()

@end

@implementation FollowingFriendsViewController

@synthesize dataSource = _dataSource;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"Following";
        
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Find Friends"
                                                                                    style:UIBarButtonItemStyleBordered
                                                                                   target:self
                                                                                   action:@selector(findFriends)]];
        
        // Get friends being followed
        NSMutableArray *facebookFriendsOnBanyan = [[NSUserDefaults standardUserDefaults] objectForKey:BNUserDefaultsBanyanUsersFacebookFriends];
        NSSortDescriptor *followingSortDescriptor =[NSSortDescriptor sortDescriptorWithKey:USER_BEING_FOLLOWED ascending:NO];
        NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:USER_NAME ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *sortArray = [NSArray arrayWithObjects:followingSortDescriptor, nameSortDescriptor, nil];
        NSArray *sortedFriendsOnBanyan = [facebookFriendsOnBanyan sortedArrayUsingDescriptors:sortArray];
        self.dataSource = sortedFriendsOnBanyan;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.dataSource = nil;
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
    cell.followButton.selected = [[cell.user objectForKey:USER_BEING_FOLLOWED] boolValue];
    
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
    User *currentUser = [User currentUser];
    NSMutableDictionary *cellUser = cell.user;
    if ([cell.followButton isSelected]) {
        // Unfollow
        cell.followButton.selected = NO;
        Activity *activity = [Activity activityWithType:kBNActivityTypeUnfollowUser
                                                      fromUser:currentUser.userId
                                                        toUser:[cellUser objectForKey:@"objectId"]
                                                       sceneId:nil
                                                       storyId:nil];
        [Activity createActivity:activity];
        [self changeFollowingStatusForUser:cellUser toStatus:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:BNUserFollowingChangedNotification object:nil];
    } else {
        // Follow
        cell.followButton.selected = YES;
        Activity *activity = [Activity activityWithType:kBNActivityTypeFollowUser
                                               fromUser:currentUser.userId
                                                 toUser:[cellUser objectForKey:@"objectId"]
                                                sceneId:nil
                                                storyId:nil];
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
    [newCellUser setObject:[NSNumber numberWithBool:!status] forKey:USER_BEING_FOLLOWED];
    NSUInteger index = [facebookFriendsOnBanyan indexOfObject:newCellUser];
    [newCellUser setObject:[NSNumber numberWithBool:status] forKey:USER_BEING_FOLLOWED];
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

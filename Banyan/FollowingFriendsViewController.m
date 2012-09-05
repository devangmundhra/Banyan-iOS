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
        NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:kBNActivityTypeFollowUser, kBNActivityTypeKey, [User currentUser].userId, kBNActivityFromUserKey, nil];
        
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
        
        if (!jsonData) {
            NSLog(@"NSJSONSerialization failed %@", error);
        }
        
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        NSMutableDictionary *getFollowActivities = [NSMutableDictionary dictionaryWithObject:json forKey:@"where"];
        
        [[AFParseAPIClient sharedClient] getPath:PARSE_API_CLASS_URL(kBNActivityClassKey)
                                      parameters:getFollowActivities
                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             NSDictionary *results = (NSDictionary *)responseObject;
                                             NSMutableArray *userIdArray = [NSMutableArray array];
                                             for (NSDictionary *activity in [results objectForKey:@"results"]) {
                                                 // Get the user being followed
                                                 [userIdArray addObject:[activity objectForKey:kBNActivityToUserKey]];
                                             }
                                             // Get the user object of the users I am following
                                             NSDictionary *constraint = [NSDictionary dictionaryWithObject:userIdArray forKey:@"$in"];
                                             NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObject:constraint forKey:@"objectId"];
                                             
                                             NSError *error = nil;
                                             NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
                                             
                                             if (!jsonData) {
                                                 NSLog(@"NSJSONSerialization failed %@", error);
                                             }
                                             
                                             NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                                             
                                             NSMutableDictionary *getFollowingUsers = [NSMutableDictionary dictionaryWithObject:json forKey:@"where"];
                                             
                                             [[AFParseAPIClient sharedClient] getPath:PARSE_API_USER_URL(@"")
                                                                           parameters:getFollowingUsers
                                                                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                                  self.dataSource = [(NSDictionary *)responseObject objectForKey:@"results"];
                                                                                  [self.tableView reloadData];
                                                                              }
                                                                              failure:AF_PARSE_ERROR_BLOCK()];
                                         }
                                         failure:AF_PARSE_ERROR_BLOCK()];
        
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
    cell.followButton.selected = YES;
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
//    PAPAccountViewController *accountViewController = [[PAPAccountViewController alloc] initWithStyle:UITableViewStylePlain];
//    [accountViewController setUser:aUser];
//    [self.navigationController pushViewController:accountViewController animated:YES];
}

- (void)cell:(FollowingUsersCell *)cellView didTapFollowButton:(NSDictionary *)aUser {
    [self shouldToggleFollowFriendForCell:cellView];
}


#pragma mark target - actions

- (void)shouldToggleFollowFriendForCell:(FollowingUsersCell *)cell {
    User *currentUser = [User currentUser];
    NSDictionary *cellUser = cell.user;
    if ([cell.followButton isSelected]) {
        // Unfollow
        cell.followButton.selected = NO;
        BNOperationObject *activityObj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeActivity tempId:nil storyId:nil];
        BNOperation *activityOp = [[BNOperation alloc] initWithObject:activityObj action:BNOperationActionDelete dependencies:nil];
        activityOp.action.context = [Activity activityWithType:kBNActivityTypeFollowUser
                                                      fromUser:currentUser.userId
                                                        toUser:[cellUser objectForKey:@"objectId"]
                                                       sceneId:nil
                                                       storyId:nil];
        ADD_OPERATION_TO_QUEUE(activityOp);
        [[NSNotificationCenter defaultCenter] postNotificationName:BNUserFollowingChangedNotification object:nil];
    } else {
        // Follow
        cell.followButton.selected = YES;
        BNOperationObject *activityObj = [[BNOperationObject alloc] initWithObjectType:BNOperationObjectTypeActivity tempId:nil storyId:nil];
        BNOperation *activityOp = [[BNOperation alloc] initWithObject:activityObj action:BNOperationActionCreate dependencies:nil];
        activityOp.action.context = [Activity activityWithType:kBNActivityTypeFollowUser
                                                      fromUser:currentUser.userId
                                                        toUser:[cellUser objectForKey:@"objectId"]
                                                       sceneId:nil
                                                       storyId:nil];
        ADD_OPERATION_TO_QUEUE(activityOp);
        [[NSNotificationCenter defaultCenter] postNotificationName:BNUserFollowingChangedNotification object:nil];
    }
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

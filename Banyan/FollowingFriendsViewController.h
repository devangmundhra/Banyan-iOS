//
//  FollowingFriendsViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 9/2/12.
//
//

#import <UIKit/UIKit.h>
#import "FollowingUsersCell.h"
#import "BNOperationQueue.h"
#import "Activity.h"

@interface FollowingFriendsViewController : UITableViewController <FollowingUsersCellDelegate>

@property (nonatomic, strong) NSMutableArray *dataSource;

@end
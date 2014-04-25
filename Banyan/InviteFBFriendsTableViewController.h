//
//  InviteFBFriendsTableViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 4/25/14.
//
//

#import <UIKit/UIKit.h>
#import "InviteFriendCell.h"
#import "BNPermissionsObject.h"

@class InviteFBFriendsTableViewController;

@protocol InviteFBFriendsTableViewControllerDelegate <NSObject>

- (void) invitedFBFriendsViewController:(InviteFBFriendsTableViewController *)inviteFBFriendsViewController
             finishedInvitingForViewers:(NSMutableArray *)selectedViewers
                           contributors:(NSMutableArray *)selectedContributors;
@end

@interface InviteFBFriendsTableViewController : UITableViewController
@property (nonatomic, weak) id<InviteFBFriendsTableViewControllerDelegate> delegate;

- (id)initWithViewerPermissions:(BNPermissionsObject<BNPermissionsObject> *)viewerPermission
          contributorPermission:(BNPermissionsObject<BNPermissionsObject> *)contributorPermission;
@end

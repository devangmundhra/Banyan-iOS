//
//  InvitedFBFriendsViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 10/19/13.
//
//

#import <UIKit/UIKit.h>
#import "InviteFriendCell.h"
#import "BNPermissionsObject.h"

@class InvitedFBFriendsViewController;

@protocol InvitedFBFriendsViewControllerDelegate <NSObject>

- (void) invitedFBFriendsViewController:(InvitedFBFriendsViewController *)invitedFBFriendsViewController
             finishedInvitingForViewers:(NSMutableArray *)selectedViewers
                           contributors:(NSMutableArray *)selectedContributors;
@end

@interface InvitedFBFriendsViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, InviteFriendCellDelegate>

@property (nonatomic, weak) id<InvitedFBFriendsViewControllerDelegate> delegate;

- (id)initWithViewerPermissions:(BNPermissionsObject *)viewerPermission
          contributorPermission:(BNPermissionsObject *)contributorPermission;

@end

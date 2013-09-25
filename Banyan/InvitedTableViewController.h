//
//  InvitedTableViewController.h
//  Storied
//
//  Created by Devang Mundhra on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InviteFriendCell.h"

@class InvitedTableViewController;

// These correspond to the index for UISegmentedControl for Write
typedef enum {
    ContributorPrivacySegmentedControlPublic = 0,
    ContributorPrivacySegmentedControlInvited = 1,
} StoryPrivacySegmentIndex;

// These correspond to the index for UISegmentedControl for Read
typedef enum {
    ViewerPrivacySegmentedControlPublic = 0,
    ViewerPrivacySegmentedControlLimited = 1,
    ViewerPrivacySegmentedControlInvited = 2,
} ViewerPrivacySegmentedControl;

@protocol InvitedTableViewControllerDelegate <NSObject>

- (void) invitedTableViewController:(InvitedTableViewController *)invitedTableViewController
         finishedInvitingForViewers:(NSArray *)selectedViewers
                       contributors:(NSArray *)selectedContributors;
@end

@interface InvitedTableViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate, InviteFriendCellDelegate>

@property (nonatomic, strong) id<InvitedTableViewControllerDelegate> delegate;

- (id)initWithViewerPermissions:(NSDictionary *)viewerPermission contributorPermission:(NSDictionary *)contributorPermission;

@end

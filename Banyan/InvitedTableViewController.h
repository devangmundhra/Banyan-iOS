//
//  InvitedTableViewController.h
//  Storied
//
//  Created by Devang Mundhra on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BNPermissionsObject.h"
#import "InvitedFBFriendsViewController.h"

@class InvitedTableViewController;

@protocol InvitedTableViewControllerDelegate <NSObject>

- (void) invitedTableViewController:(InvitedTableViewController *)invitedTableViewController
         finishedInvitingForViewerPermissions:(BNPermissionsObject *)viewerPermissions
                       contributorPermissions:(BNPermissionsObject *)contributorPermissions;
@end

@interface InvitedTableViewController : UITableViewController <InvitedFBFriendsViewControllerDelegate>

@property (nonatomic, weak) id<InvitedTableViewControllerDelegate> delegate;

- (id)initWithViewerPermissions:(BNPermissionsObject *)viewerPermission contributorPermission:(BNPermissionsObject *)contributorPermission;

@end

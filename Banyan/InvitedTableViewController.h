//
//  InvitedTableViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 4/7/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BNPermissionsObject.h"
#import "InvitedFBFriendsViewController.h"

@class InvitedTableViewController;

@protocol InvitedTableViewControllerDelegate <NSObject>

- (void) invitedTableViewController:(InvitedTableViewController *)invitedTableViewController
         finishedInvitingForViewerPermissions:(BNPermissionsObject<BNPermissionsObject> *)viewerPermissions
                       contributorPermissions:(BNPermissionsObject<BNPermissionsObject> *)contributorPermissions;
@end

@interface InvitedTableViewController : UITableViewController <InvitedFBFriendsViewControllerDelegate>

@property (nonatomic, weak) id<InvitedTableViewControllerDelegate> delegate;

- (id)initWithViewerPermissions:(BNPermissionsObject<BNPermissionsObject> *)viewerPermission
          contributorPermission:(BNPermissionsObject<BNPermissionsObject> *)contributorPermission;

@end

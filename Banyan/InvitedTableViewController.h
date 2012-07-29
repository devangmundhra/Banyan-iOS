//
//  InvitedTableViewController.h
//  Storied
//
//  Created by Devang Mundhra on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserManagementModule.h"
#import <Parse/Parse.h>
#import "BanyanAppDelegate.h"

@class InvitedTableViewController;

#define INVITED_VIEWERS_STRING @"Viewers"
#define INVITED_CONTRIBUTORS_STRING @"Contributors"
@protocol InvitedTableViewControllerDelegate <NSObject>

- (void) invitedTableViewController:(InvitedTableViewController *)invitedTableViewController 
                   finishedInviting:(NSString *)invitingType 
                       withContacts:(NSArray *)contactsList;

@end

@interface InvitedTableViewController : UITableViewController <PF_FBRequestDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, weak) NSManagedObjectContext *objectContext;
@property (nonatomic, weak) id<InvitedTableViewControllerDelegate> delegate;
@property (nonatomic, weak) NSString *invitationType;
@property (nonatomic, copy) NSMutableArray *selectedContacts;

- (id) initWithSearchBarAndNavigationControllerForInvitationType:(NSString *)invitationType delegate:(id<InvitedTableViewControllerDelegate>)delegate selectedContacts:(NSArray *)selectedContacts;
@end

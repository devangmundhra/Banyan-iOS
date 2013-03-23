//
//  InvitedTableViewController.h
//  Storied
//
//  Created by Devang Mundhra on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@class InvitedTableViewController;

#define INVITED_VIEWERS_STRING @"Viewers"
#define INVITED_CONTRIBUTORS_STRING @"Contributors"
@protocol InvitedTableViewControllerDelegate <NSObject>

- (void) invitedTableViewController:(InvitedTableViewController *)invitedTableViewController 
                   finishedInviting:(NSString *)invitingType 
                       withContacts:(NSArray *)contactsList;

- (void) invitedTableViewControllerDidCancel:(InvitedTableViewController *)invitedTableViewController;
@end

@interface InvitedTableViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, weak) NSManagedObjectContext *objectContext;
@property (nonatomic, weak) id<InvitedTableViewControllerDelegate> delegate;
@property (nonatomic, weak) NSString *invitationType;
@property (nonatomic, copy) NSMutableArray *selectedContacts;

@end

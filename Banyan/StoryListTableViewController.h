//
//  StoryListTableViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StoryListStoryCell.h"
#import "Story+Create.h"
#import "Story+Delete.h"
#import "Scene+Create.h"
#import "NewStoryViewController.h"
#import "ScenesViewController.h"
#import "AppDelegate.h"
#import "UserLoginViewController.h"
#import "UserManagementModule.h"
#import "PullToRefreshView.h"
#import "MBProgressHUD.h"

@interface StoryListTableViewController : UITableViewController <NewStoryViewControllerDelegate, ScenesViewControllerDelegate, PullToRefreshViewDelegate> {
    PullToRefreshView *_pull;
}

@property (nonatomic, strong) NSMutableArray *dataSource;

- (Story *)lookForStoryId:(NSString *)storyId;

@end

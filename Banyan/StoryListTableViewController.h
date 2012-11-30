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
#import "File+Create.h"
#import "NewStoryViewController.h"
#import "ScenesViewController.h"
#import "UserLoginViewController.h"
#import "PullToRefreshView.h"
#import "MBProgressHUD.h"
#import "BanyanDataSource.h"
#import "SettingsTableViewController.h"

@interface StoryListTableViewController : TISwipeableTableViewController <NewStoryViewControllerDelegate, ScenesViewControllerDelegate, PullToRefreshViewDelegate, ModifySceneViewControllerDelegate> {
    PullToRefreshView *_pull;
}

@property (nonatomic, strong) NSMutableArray *dataSource;
- (void)addSceneForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

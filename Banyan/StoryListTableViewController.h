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
#import "Piece+Create.h"
#import "File+Create.h"
#import "NewStoryViewController.h"
#import "StoryReaderController.h"
#import "UserLoginViewController.h"
#import "MBProgressHUD.h"
#import "SettingsTableViewController.h"
#import "CoreDataTableViewController.h"
#import "BanyanConnection.h"

@interface StoryListTableViewController : CoreDataTableViewController <NewStoryViewControllerDelegate, StoryReaderControllerDelegate, ModifySceneViewControllerDelegate>

- (void)addSceneForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

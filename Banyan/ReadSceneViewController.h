//
//  ReadSceneViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Scene_Defines.h"
#import "Story_Defines.h"
#import "Story+Edit.h"
#import "ModifySceneViewController.h"
#import "AppDelegate.h"
#import "UIImageView+AFNetworking.h"
#import <Parse/Parse.h>
#import "User_Defines.h"
#import "InvitedTableViewController.h"
#import "BanyanAPIEngine.h"

@class ReadSceneViewController;

@protocol ReadSceneViewControllerDelegate <NSObject>

- (void)doneWithReadSceneViewController:(ReadSceneViewController *)readSceneViewController;
- (void)readSceneViewControllerAddedNewScene:(ReadSceneViewController *)readSceneViewController;
- (void)readSceneViewControllerDeletedScene:(ReadSceneViewController *)readSceneViewController;
- (void)readSceneViewControllerDeletedStory:(ReadSceneViewController *)readSceneViewController;
- (BOOL)readSceneControllerEditMode;
- (void)setReadSceneControllerEditMode:(BOOL)readSceneControllerEditMode;

@end

@interface ReadSceneViewController : UIViewController <UIGestureRecognizerDelegate, ModifySceneViewControllerDelegate, InvitedTableViewControllerDelegate>

@property (strong, nonatomic) Scene *scene;
@property (weak, nonatomic) IBOutlet id <ReadSceneViewControllerDelegate> delegate;
@end
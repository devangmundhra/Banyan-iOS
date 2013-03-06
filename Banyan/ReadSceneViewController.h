//
//  ReadSceneViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Piece_Defines.h"
#import "Story_Defines.h"
#import "Story+Edit.h"
#import "ModifySceneViewController.h"
#import "BanyanAppDelegate.h"
#import "UIImageView+AFNetworking.h"
#import <Parse/Parse.h>
#import "User_Defines.h"
#import "InvitedTableViewController.h"

@class ReadSceneViewController;

@protocol ReadSceneViewControllerDelegate <NSObject>

- (void)doneWithReadSceneViewController:(ReadSceneViewController *)readSceneViewController;
- (void)readSceneViewControllerAddedNewScene:(ReadSceneViewController *)readSceneViewController;
- (void)readSceneViewControllerDeletedScene:(ReadSceneViewController *)readSceneViewController;
- (void)readSceneViewControllerDeletedStory:(ReadSceneViewController *)readSceneViewController;
- (BOOL)readSceneControllerEditMode;
- (void)setReadSceneControllerEditMode:(BOOL)readSceneControllerEditMode;

@end

@interface ReadSceneViewController : UIViewController </*UIGestureRecognizerDelegate, */ModifySceneViewControllerDelegate, InvitedTableViewControllerDelegate, BNLocationManagerDelegate>

@property (strong, nonatomic) Piece *piece;
@property (weak, nonatomic) IBOutlet id <ReadSceneViewControllerDelegate> delegate;

- (IBAction)addPiece:(UIBarButtonItem *)sender;

@end
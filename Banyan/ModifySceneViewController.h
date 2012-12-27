//
//  ModifySceneViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Piece.h"
#import "Story.h"
#import "BNLocationManager.h"
#import "ComposeTextViewController.h"

@class  ModifySceneViewController;

typedef enum {add, edit} EditModes;

@protocol ModifySceneViewControllerDelegate <NSObject>

- (void) modifySceneViewControllerDidCancel:(ModifySceneViewController *)controller;

@optional
- (void) modifySceneViewControllerDeletedScene:(ModifySceneViewController *)controller;

- (void) modifySceneViewController:(ModifySceneViewController *)controller
             didFinishEditingScene:(Piece *)scene;

- (void) modifySceneViewController:(ModifySceneViewController *)controller
              didFinishAddingScene:(Piece *)scene;

- (void) modifySceneViewControllerDeletedStory:(ModifySceneViewController *)controller;

@end

@interface ModifySceneViewController : UIViewController <UITextViewDelegate, UINavigationControllerDelegate, ComposeTextViewControllerDelegate, UIAlertViewDelegate,
    UIImagePickerControllerDelegate, UINavigationBarDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, BNLocationManagerDelegate>

@property (strong, nonatomic) Piece *piece;
@property (nonatomic) EditModes editMode;
@property (weak, nonatomic) id <ModifySceneViewControllerDelegate> delegate;

@end

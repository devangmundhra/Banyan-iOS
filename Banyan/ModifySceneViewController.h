//
//  ModifySceneViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Scene.h"
#import "Story.h"
#import "BNLocationManager.h"
#import "ComposeTextViewController.h"

@class  ModifySceneViewController;

typedef enum {add, edit} EditModes;

@protocol ModifySceneViewControllerDelegate <NSObject>

- (void) modifySceneViewController:(ModifySceneViewController *)controller
             didFinishEditingScene:(Scene *)scene;

- (void) modifySceneViewController:(ModifySceneViewController *)controller
              didFinishAddingScene:(Scene *)scene;

- (void) modifySceneViewController:(ModifySceneViewController *)controller;

- (void) modifySceneViewControllerDeletedStory:(ModifySceneViewController *)controller;

- (void) modifySceneViewControllerDidCancel:(ModifySceneViewController *)controller;

@end

@interface ModifySceneViewController : UIViewController <UITextViewDelegate, UINavigationControllerDelegate, ComposeTextViewControllerDelegate,
    UIImagePickerControllerDelegate, UINavigationBarDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, BNLocationManagerDelegate>

@property (strong, nonatomic) Scene *scene;
@property (nonatomic) EditModes editMode;
@property (weak, nonatomic) id <ModifySceneViewControllerDelegate> delegate;

@end

//
//  ModifyStoryViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InvitedTableViewController.h"
#import "BNFBLocationManager.h"
#import "LocationPickerButton.h"
#import "MediaPickerViewController.h"
#import "SingleImagePickerButton.h"
#import "Story+Create.h"
#import "AVCamViewController.h"

@class ModifyStoryViewController;

@protocol ModifyStoryViewControllerDelegate <NSObject>

- (void) modifyStoryViewControllerDidSelectStory:(Story *)story;
@optional
- (void) modifyStoryViewControllerDidDismiss:(ModifyStoryViewController *)viewController;

@end

typedef enum {ModifyStoryViewControllerEditModeAdd, ModifyStoryViewControllerEditModeEdit} ModifyStoryViewControllerEditMode;

@interface ModifyStoryViewController : UIViewController <InvitedTableViewControllerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) Story *story;
@property (strong, nonatomic) id <ModifyStoryViewControllerDelegate>delegate;

- (id) initWithStory:(Story *)story;

@end
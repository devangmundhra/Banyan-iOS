//
//  NewStoryViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InvitedTableViewController.h"
#import "BNFBLocationManager.h"
#import "TITokenField.h"
#import "LocationPickerButton.h"
#import "MediaPickerViewController.h"
#import "MediaPickerButton.h"
#import "Story+Create.h"

@class ModifyStoryViewController;
typedef enum {ModifyStoryViewControllerEditModeAdd, ModifyStoryViewControllerEditModeEdit} ModifyStoryViewControllerEditMode;

@interface ModifyStoryViewController : UIViewController <UITextFieldDelegate, InvitedTableViewControllerDelegate, UIScrollViewDelegate, BNFBLocationManagerDelegate, TITokenFieldDelegate, LocationPickerButtonDelegate, MediaPickerButtonDelegate, MediaPickerViewControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) Story *story;

- (id) initWithStory:(Story *)story;

@end
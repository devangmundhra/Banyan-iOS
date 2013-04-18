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
#import "Story.h"
#import "LocationPickerButton.h"
#import "MediaPickerViewController.h"
#import "MediaPickerButton.h"

@class NewStoryViewController;
typedef enum {NewStoryViewControllerEditModeAdd, NewStoryViewControllerEditModeEdit} NewStoryViewControllerEditMode;

@interface NewStoryViewController : UIViewController <UITextFieldDelegate, InvitedTableViewControllerDelegate, UIScrollViewDelegate, BNFBLocationManagerDelegate, TITokenFieldDelegate, LocationPickerButtonDelegate, MediaPickerButtonDelegate, MediaPickerViewControllerDelegate, UIActionSheetDelegate>

// Delegate to save the story and close the window on done and edit

@end
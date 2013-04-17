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

@protocol NewStoryViewControllerDelegate <NSObject>

- (void) newStoryViewController:(NewStoryViewController *)sender didAddStory:(Story *)story;
- (void) newStoryViewControllerDidCancel:(NewStoryViewController *)sender;

@end

@interface NewStoryViewController : UIViewController <UITextFieldDelegate, InvitedTableViewControllerDelegate, UIScrollViewDelegate, BNFBLocationManagerDelegate, TITokenFieldDelegate, LocationPickerButtonDelegate, MediaPickerButtonDelegate, MediaPickerViewControllerDelegate, UIActionSheetDelegate>

// Delegate to save the story and close the window on done and edit
@property (weak, nonatomic) IBOutlet id <NewStoryViewControllerDelegate> delegate;

@end
//
//  NewStoryViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Story+Create.h"
#import "InvitedTableViewController.h"
#import "BNLocationManager.h"
#import "TITokenField.h"

@class NewStoryViewController;
@class Story;

@protocol NewStoryViewControllerDelegate <NSObject>

- (void) newStoryViewController:(NewStoryViewController *)sender didAddStory:(Story *)story;
- (void) newStoryViewControllerDidCancel:(NewStoryViewController *)sender;

@end

@interface NewStoryViewController : UIViewController <UITextFieldDelegate, InvitedTableViewControllerDelegate, UIScrollViewDelegate, BNLocationManagerDelegate, TITokenFieldDelegate>

// Delegate to save the story and close the window on done and edit
@property (weak, nonatomic) IBOutlet id <NewStoryViewControllerDelegate> delegate;

@end
//
//  NewStoryViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Story+Create.h"
#import "InvitedTableViewController.h"

@class NewStoryViewController;
@class Story;

@protocol NewStoryViewControllerDelegate <NSObject>

- (void) newStoryViewController:(NewStoryViewController *) sender didAddStory:(Story *)story;

@end

@interface NewStoryViewController : UIViewController <UITextFieldDelegate, InvitedTableViewControllerDelegate, CLLocationManagerDelegate, UIScrollViewDelegate>

// Delegate to save the story and close the window on done and edit
@property (weak, nonatomic) IBOutlet id <NewStoryViewControllerDelegate> delegate;

@end
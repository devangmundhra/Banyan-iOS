//
//  StoryPickerViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 7/28/13.
//
//

#import <UIKit/UIKit.h>
#import "ModifyStoryViewController.h"

@protocol StoryPickerViewControllerDelegate <NSObject>

- (void) storyPickerViewControllerDidPickStory:(Story *)story;

@end

@interface StoryPickerViewController : UITableViewController <ModifyStoryViewControllerDelegate>

@property (strong, nonatomic) id <StoryPickerViewControllerDelegate> delegate;

@end

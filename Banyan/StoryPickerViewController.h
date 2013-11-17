//
//  StoryPickerViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 10/28/13.
//
//

#import <UIKit/UIKit.h>
#import "StoryPickerCell.h"

@protocol StoryPickerViewControllerDelegate <NSObject>

- (void) storyPickerViewControllerDidPickStory:(Story *)story;

@end

@interface StoryPickerViewController : UICollectionViewController

@property (weak, nonatomic) id <StoryPickerViewControllerDelegate> delegate;

@end

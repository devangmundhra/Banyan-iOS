//
//  StoryPickerCell.h
//  Banyan
//
//  Created by Devang Mundhra on 10/29/13.
//
//

#import <UIKit/UIKit.h>
#import "Story.h"

@interface StoryPickerCell : UICollectionViewCell

- (void)setStory:(Story *)story;
- (void)displayAsAddStoryButton;

@end

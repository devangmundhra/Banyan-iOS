//
//  StoryListStoryCell.h
//  Storied
//
//  Created by Devang Mundhra on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+AFNetworking.h"

@interface StoryListStoryCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *storyTitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *storyImageView;
@property (nonatomic, strong) IBOutlet UILabel *storyLocationLabel;
@end

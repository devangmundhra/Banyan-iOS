//
//  StoryListStoryCell.h
//  Storied
//
//  Created by Devang Mundhra on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+AFNetworking.h"
#import "UIImage+ResizeAdditions.h"
#import "UIImage+RoundedCornerAdditions.h"
#import "UIImage+AlphaAdditions.h"
#import "TISwipeableTableView.h"
#import "UIImage+Create.h"

#define TABLE_CELL_MARGIN 10.0
#define TABLE_ROW_HEIGHT 60.0

@interface StoryListStoryCell : TISwipeableTableViewCell <UIAlertViewDelegate>

@property (nonatomic, strong) IBOutlet UILabel *storyTitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *storyImageView;
@property (nonatomic, strong) IBOutlet UILabel *storyLocationLabel;
@end

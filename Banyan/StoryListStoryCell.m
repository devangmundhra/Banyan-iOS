//
//  StoryListStoryCell.m
//  Storied
//
//  Created by Devang Mundhra on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryListStoryCell.h"

@implementation StoryListStoryCell

@synthesize storyTitleLabel = _storyTitleLabel;
@synthesize storyImageView = _storyImageView;
@synthesize storyLocationLabel = _storyLocationLabel;

- (void)setStoryImageView:(UIImageView *)storyImageView
{
    _storyImageView = storyImageView;
    _storyImageView.contentMode = UIViewContentModeScaleAspectFill;
    _storyImageView.clipsToBounds = YES;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.imageView.contentMode = UIViewContentModeCenter;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

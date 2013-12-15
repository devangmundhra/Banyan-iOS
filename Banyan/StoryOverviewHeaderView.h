//
//  StoryOverviewHeaderView.h
//  Banyan
//
//  Created by Devang Mundhra on 12/13/13.
//
//

#import <UIKit/UIKit.h>
#import "Story.h"

#define STORYOVERVIEW_HEADERVIEW_HEIGHT 64

@interface StoryOverviewHeaderView : UICollectionReusableView
@property (strong, nonatomic) Story *story;

@end

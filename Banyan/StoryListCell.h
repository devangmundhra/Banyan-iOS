//
//  StoryListCell.h
//  Banyan
//
//  Created by Devang Mundhra on 3/18/13.
//
//

#import <UIKit/UIKit.h>
#import "Story.h"
#import "Story_Defines.h"
#import "UISwipeableView.h"

#define TABLE_CELL_MARGIN 10.0
#define TABLE_ROW_HEIGHT 200.0 // from nib file

@interface StoryListCell : UITableViewCell <UISwipeableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) IBOutlet Story* story;

- (void) hideSwipedViewAnimated:(BOOL)animated;
- (void) revealSwipedViewAnimated:(BOOL)animated;

@end

@interface UIViewWithTopLine : UIView
@end
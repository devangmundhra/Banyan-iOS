//
//  StoryListTableViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BNTableViewController.h"
#import "StoryListCell.h"

@interface StoryListTableViewController : BNTableViewController <StoryListCellDelegate> {
	NSIndexPath * indexOfVisibleBackView;
} 

@end

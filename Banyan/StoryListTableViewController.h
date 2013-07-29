//
//  StoryListTableViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"
#import "SingleStoryCell.h"

@interface StoryListTableViewController : CoreDataTableViewController <SingleStoryCellDelegate> {
	NSIndexPath * indexOfVisibleBackView;
}

-(void) addPieceToStory:(Story *)story;

@end

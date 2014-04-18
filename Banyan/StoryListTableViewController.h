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
#import "StoryPickerViewController.h"

@interface StoryListTableViewController : CoreDataTableViewController <SingleStoryCellDelegate, StoryPickerViewControllerDelegate>

- (void) addPieceToStory:(Story *)story;
- (void)storyReaderWithStory:(Story *)story piece:(Piece *)piece;

@end
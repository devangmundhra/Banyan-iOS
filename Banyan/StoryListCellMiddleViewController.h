//
//  StoryListCellMiddleViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 3/21/13.
//
//

#import <UIKit/UIKit.h>
#import "Story.h"
#import "Story_Defines.h"

@interface StoryListCellMiddleViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet Story* story;

- (Piece *)currentlyVisiblePiece;

@end

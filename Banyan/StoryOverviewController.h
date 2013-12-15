//
//  StoryOverviewController.h
//  Banyan
//
//  Created by Devang Mundhra on 12/12/13.
//
//

#import <UIKit/UIKit.h>
#import "Story.h"

@protocol StoryOverviewControllerDelegate <NSObject>

- (void) storyOverviewControllerSelectedPiece:(Piece *)piece;
- (void) storyOverviewControllerDeletedStory;

@end

@interface StoryOverviewController : UIViewController
@property (weak, nonatomic) IBOutlet id<StoryOverviewControllerDelegate> delegate;

- (id)initWithStory:(Story *)story;

@end

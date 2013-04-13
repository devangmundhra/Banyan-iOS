//
//  StoryListCellReadSceneViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 3/21/13.
//
//

#import <UIKit/UIKit.h>
#import "Piece.h"

@interface StoryListCellReadSceneViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

- (void) setPiece:(Piece *)piece;

@end

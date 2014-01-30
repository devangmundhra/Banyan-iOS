//
//  SinglePieceView.h
//  Banyan
//
//  Created by Devang Mundhra on 6/16/13.
//
//

#import <UIKit/UIKit.h>
#import "Piece.h"
#import "UIImageView+BanyanMedia.h"

#define ALPHA_OF_READ_STORY 0.6
@interface SinglePieceView : UIImageView
@property (strong, nonatomic) Piece *piece;
@property (nonatomic) NSUInteger pieceNum;

- (void) resetView;
- (void) setStatusForView:(NSString *)status font:(UIFont *)font;

@end

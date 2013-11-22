//
//  SinglePieceView.m
//  Banyan
//
//  Created by Devang Mundhra on 6/16/13.
//
//
/* Note: The operationKey part has been copied from SDWebImage UIImageView category so that 
 * the resizing part (done by the Media class method) can be used directly
 */
#import "SinglePieceView.h"
#import <QuartzCore/QuartzCore.h>
#import "BNLabel.h"

static UIFont *_boldCondensedFont;
static UIFont *_regularFont;

@interface SinglePieceView ()
@property (strong, nonatomic) UILabel *textLabel;
@end

@implementation SinglePieceView

@synthesize piece = _piece;
@synthesize pieceNum = _pieceNum;
@synthesize textLabel = _textLabel;

+ (void)initialize
{
    _boldCondensedFont = [UIFont fontWithName:@"Roboto-BoldCondensed" size:16];
    _regularFont = [UIFont fontWithName:@"Roboto-Regular" size:12];
}

#define ARC4RANDOM_MAX      0x100000000

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = YES;
        self.backgroundColor = [UIColor colorWithRed:((double)arc4random() / ARC4RANDOM_MAX) green:((double)arc4random() / ARC4RANDOM_MAX) blue:((double)arc4random() / ARC4RANDOM_MAX) alpha:1];
        self.clipsToBounds = YES;
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        CGRect localFrame = self.bounds;
        localFrame.origin.x += 15;
        localFrame.origin.y += CGRectGetHeight(localFrame)/2;
        localFrame.size.width -= 30;
        localFrame.size.height = CGRectGetHeight(localFrame)/2;
        
        self.textLabel = [[UILabel alloc] initWithFrame:localFrame];
        self.textLabel.hidden = YES;
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = BANYAN_BLACK_COLOR;
        self.textLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:self.textLabel];
    }
    return self;
}

- (void)setPiece:(Piece *)piece
{    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BNRefreshCurrentStoryListNotification object:_piece];
    _piece = piece;
    // Add a notification observer for this piece so that when this piece gets edited, the view can be refreshed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadPiece)
                                                 name:BNRefreshCurrentStoryListNotification
                                               object:piece];
    
    [self loadPiece];
}

- (void) loadPiece
{
    [self cancelCurrentImageLoad];
    if (self.piece) {
        Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.piece.media];
        [self showMedia:imageMedia withPostProcess:nil];
        if ([self.piece.shortText length]) {
            self.textLabel.hidden = NO;
            self.textLabel.font = _boldCondensedFont;
            self.textLabel.text = self.piece.shortText;
        } else if ([self.piece.longText length]) {
            self.textLabel.hidden = NO;
            self.textLabel.text = self.piece.longText;
            self.textLabel.font = _regularFont;
        }
    } else {
        [self setStatusForView:@"Error in loading piece." font:_regularFont];
    }
}

- (void) setStatusForView:(NSString *)status font:(UIFont *)font
{
    self.image = nil;
    self.textLabel.hidden = NO;
    self.textLabel.text = status;
    self.textLabel.font = font;
    self.textLabel.textColor = BANYAN_BROWN_COLOR;
}

- (void)resetView
{
    self.textLabel.hidden = YES;
    _piece = nil;
    self.pieceNum = 0;
    self.textLabel.textColor = BANYAN_BLACK_COLOR;
    [self cancelCurrentImageLoad];
}

@end

//
//  StoryOverviewPieceCell.m
//  Banyan
//
//  Created by Devang Mundhra on 12/12/13.
//
//

#import "StoryOverviewPieceCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+BanyanMedia.h"

@interface StoryOverviewPieceCell ()
@property (strong, nonatomic) UILabel *pieceLabel;
@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation StoryOverviewPieceCell
@synthesize piece = _piece;
@synthesize pieceLabel = _pieceLabel;
@synthesize imageView = _imageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CGRect frame = self.bounds;

        self.backgroundColor = BANYAN_WHITE_COLOR;
        self.layer.borderWidth = 1.0f;
        self.layer.borderColor = BANYAN_LIGHTGRAY_COLOR.CGColor;
        self.layer.cornerRadius = CGRectGetWidth(frame)/2;
        self.clipsToBounds = YES;
        self.layer.masksToBounds = YES;
        
        self.imageView = [[UIImageView alloc] initWithFrame:frame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.backgroundColor = BANYAN_WHITE_COLOR;
        [self addSubview:self.imageView];
        
        self.pieceLabel = [[UILabel alloc] initWithFrame:frame];
        self.pieceLabel.textColor = BANYAN_BLACK_COLOR;
        self.pieceLabel.numberOfLines = 0;
        self.pieceLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.pieceLabel.textAlignment = NSTextAlignmentCenter;
        self.pieceLabel.font = [UIFont fontWithName:@"Roboto-Medium" size:12];
        [self addSubview:self.pieceLabel];
    }
    
    return self;
}

- (void)setPiece:(Piece *)piece
{
    _piece = piece;
    // Image
    Media *media = nil;
    if ((media = [Media getMediaOfType:@"image" inMediaSet:piece.media])) {
        [self.imageView showMedia:media includeThumbnail:YES withPostProcess:nil];
    }
    else if (piece.shortText.length) {
        self.pieceLabel.text = piece.shortText;
    }
    else if (piece.longText.length) {
        self.pieceLabel.text = piece.longText;
    }
    else if ((media = [Media getMediaOfType:@"audio" inMediaSet:piece.media])) {
        self.pieceLabel.text = @"Piece contains audio";
    }
}

- (void)prepareForReuse
{
    [self.imageView cancelCurrentImageLoad];
    self.imageView.image = nil;
    self.pieceLabel.text = nil;
}
@end

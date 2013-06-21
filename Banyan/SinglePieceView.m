//
//  SinglePieceView.m
//  Banyan
//
//  Created by Devang Mundhra on 6/16/13.
//
//

#import "SinglePieceView.h"
#import "Media.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "SDWebImage/UIImageView+WebCache.h"

static UIFont *_boldCondensedFont;
static UIFont *_regularFont;

@interface SinglePieceView ()
@property (strong, nonatomic) UILabel *label;
@end

@implementation SinglePieceView

@synthesize piece = _piece;
@synthesize pieceNum = _pieceNum;
@synthesize label = _label;

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
        
        self.label = [[UILabel alloc] initWithFrame:CGRectZero];
        self.label.hidden = YES;
        self.label.backgroundColor = [UIColor clearColor];
        [self addSubview:self.label];
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
    if (self.piece) {
        Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.piece.media];
        
        if (imageMedia) {
            if ([imageMedia.remoteURL length]) {
                [self setImageWithURL:[NSURL URLWithString:imageMedia.remoteURL] placeholderImage:nil options:SDWebImageProgressiveDownload];
            } else if ([imageMedia.localURL length]) {
                ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
                [library assetForURL:[NSURL URLWithString:imageMedia.localURL] resultBlock:^(ALAsset *asset) {
                    ALAssetRepresentation *rep = [asset defaultRepresentation];
                    CGImageRef imageRef = [rep fullScreenImage];
                    UIImage *image = [UIImage imageWithCGImage:imageRef];
                    [self setImage:image];
                }
                        failureBlock:^(NSError *error) {
                            NSLog(@"***** ERROR IN FILE CREATE ***\nCan't find the asset library image");
                        }
                 ];
            } else {
                [self setImageWithURL:nil];
            }
        }
        
        CGRect frame = self.bounds;
        frame.origin.x += 5;
        frame.origin.y += CGRectGetHeight(frame)/2;
        frame.size.width -= 10;
        frame.size.height = CGRectGetHeight(frame)/2;
        self.label.frame = frame;
        if (self.piece.shortText) {
            self.label.hidden = NO; // Show only if there is something to show to avoid unnecessary clearColor rendering
            self.label.font = _boldCondensedFont;
            self.label.text = self.piece.shortText;
            self.label.textColor = BANYAN_BLACK_COLOR;
            self.label.textAlignment = NSTextAlignmentLeft;
        } else if (self.piece.longText) {
            self.label.hidden = NO;
            self.label.font = _regularFont;
            self.label.text = self.piece.longText;
            self.label.textColor = BANYAN_BLACK_COLOR;
            self.label.textAlignment = NSTextAlignmentLeft;
            // Add gradient
        }
    } else {
        [self setStatusForView:@"Error in loading piece."];
    }
}

- (void) setStatusForView:(NSString *)status
{
    [self cancelCurrentImageLoad];
    self.image = nil;
    CGRect frame = self.bounds;
    frame.origin.x += 5;
    frame.origin.y += 5;
    frame.size.width -= 10;
    frame.size.height -= 10;
    self.label.frame = frame;
    self.label.hidden = NO;
    self.label.font = _regularFont;
    self.label.textColor = BANYAN_BROWN_COLOR;
    self.label.lineBreakMode = NSLineBreakByWordWrapping;
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.text = status;
}

- (void)resetView
{
    self.piece = nil;
    self.pieceNum = 0;
    [self cancelCurrentImageLoad];
    self.image = nil;
    self.label.frame = CGRectZero;
    self.label.hidden = YES;
    self.frame = CGRectZero;
}

@end

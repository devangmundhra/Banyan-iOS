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
#import "Piece+Stats.h"
#import "Story.h"

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext];
    }
    return self;
}

- (void)setPiece:(Piece *)piece
{
    _piece = piece;
    
    [self loadPiece];
}

- (void)handleManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    if (!self.piece) {
        return;
    }
    
    NSDictionary *userInfo = notification.userInfo;
    NSSet *insertedObjects = [userInfo objectForKey:NSInsertedObjectsKey];
    NSSet *updatedObjects = [userInfo objectForKey:NSUpdatedObjectsKey];
    
    if ([insertedObjects containsObject:self.piece] || [updatedObjects containsObject:self.piece]) {
        [self loadPiece];
    }
}

- (void) loadPiece
{
    [self cancelCurrentImageLoad];
    if (self.piece) {
        // Update Stats
        [Piece viewedPiece:self.piece];
        
        Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:self.piece.media];
        [self showMedia:imageMedia includeThumbnail:YES withPostProcess:nil];
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

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

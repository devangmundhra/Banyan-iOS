//
//  StoryListCellReadSceneViewController.m
//  Banyan
//
//  Created by Devang Mundhra on 3/21/13.
//
//

#import "StoryListCellReadSceneViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>
#import "Media.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface StoryListCellReadSceneViewController ()
@property (strong, nonatomic) Piece *piece;
@end

@implementation StoryListCellReadSceneViewController
@synthesize imageView = _imageView;
@synthesize textView = _textView;
@synthesize piece = _piece;

- (void) setStatus:(NSString *)status
{
    self.textView.font = [UIFont fontWithName:@"Roboto-Regular" size:16];
    self.textView.textColor = [UIColor brownColor];
    self.textView.textAlignment = NSTextAlignmentCenter;
    self.textView.text = status;
    return;
}

- (void)setPiece:(Piece *)piece
{
    // Remove any previous notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BNRefreshCurrentStoryListNotification object:_piece];
    
    _piece = piece;
    
    if (!piece) {
        [self setStatus:@"Error in loading piece."];
        return;
    }
    
    [self loadPiece:piece];
    
    // Add a notification observer for this piece so that when this piece gets edited, the view can be refreshed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshPiece:)
                                                 name:BNRefreshCurrentStoryListNotification
                                               object:piece];
}

- (void) loadPiece:(Piece *)piece
{
    Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:piece.media];
    
    if (imageMedia) {
        if ([imageMedia.remoteURL length]) {
            [self.imageView setImageWithURL:[NSURL URLWithString:imageMedia.remoteURL] placeholderImage:nil options:SDWebImageProgressiveDownload];
        } else if ([imageMedia.localURL length]) {
            ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
            [library assetForURL:[NSURL URLWithString:imageMedia.localURL] resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                CGImageRef imageRef = [rep fullScreenImage];
                UIImage *image = [UIImage imageWithCGImage:imageRef];
                [self.imageView setImage:image];
            }
                    failureBlock:^(NSError *error) {
                        NSLog(@"***** ERROR IN FILE CREATE ***\nCan't find the asset library image");
                    }
             ];
        } else {
            [self.imageView setImageWithURL:nil];
        }
    }
    
    if (piece.shortText) {
        self.textView.font = [UIFont fontWithName:@"Roboto-BoldCondensed" size:16];
        self.textView.text = piece.shortText;
        self.textView.textColor = BANYAN_BLACK_COLOR;
        self.textView.textAlignment = NSTextAlignmentLeft;
    } else if (piece.longText) {
        self.textView.font = [UIFont fontWithName:@"Roboto-Regular" size:12];
        self.textView.text = piece.longText;
        self.textView.textColor = BANYAN_BLACK_COLOR;
        self.textView.textAlignment = NSTextAlignmentLeft;
        // Add gradient
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textView.editable = NO;
    self.textView.scrollEnabled = NO;
    self.textView.backgroundColor = [UIColor clearColor];
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor clearColor];
}

- (void) refreshPiece:(NSNotification *)notification
{
    [self loadPiece:self.piece];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

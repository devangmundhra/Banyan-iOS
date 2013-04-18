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
#import "UIImageView+AFNetworking.h"

@interface StoryListCellReadSceneViewController ()

@end

@implementation StoryListCellReadSceneViewController
@synthesize imageView = _imageView;
@synthesize textView = _textView;

- (void)setPiece:(Piece *)piece
{
    if (piece.imageURL && [piece.imageURL rangeOfString:@"asset"].location == NSNotFound) {
        [self.imageView setImageWithURL:[NSURL URLWithString:piece.imageURL] placeholderImage:nil];
    } else if (piece.imageURL) {
        ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
        [library assetForURL:[NSURL URLWithString:piece.imageURL] resultBlock:^(ALAsset *asset) {
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
        [self.imageView cancelImageRequestOperation];
        [self.imageView setImageWithURL:nil];
    }
    if (piece.shortText) {
        self.textView.font = [UIFont fontWithName:@"Roboto-BoldCondensed" size:16];
        self.textView.text = piece.shortText;
    } else if (piece.longText) {
        self.textView.font = [UIFont fontWithName:@"Roboto-Regular" size:12];
        self.textView.text = piece.longText;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setImageView:nil];
    [self setTextView:nil];
    [self setPiece:nil];
    [super viewDidUnload];
}
@end

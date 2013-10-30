//
//  StoryPickerCell.m
//  Banyan
//
//  Created by Devang Mundhra on 10/29/13.
//
//

#import "StoryPickerCell.h"
#import <QuartzCore/QuartzCore.h>
#import "User.h"
#import "Story+Permissions.h"
#import "BNLabel.h"
#import "Media.h"
#import "UIImageView+WebCache.h"
#import "UIImage+ImageEffects.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SDWebImage/SDWebImageDownloader.h"

@interface StoryPickerCell ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) BNLabel *titleLabel;
@property (strong, nonatomic) BNLabel *authorLabel;
@property (strong, nonatomic) BNLabel *fullLabel;

@end

@implementation StoryPickerCell

#define TEXT_INSETS 6
#define VIEW_INSETS 8

@synthesize imageView = _imageView;
@synthesize titleLabel = _titleLabel;
@synthesize authorLabel = _authorLabel;
@synthesize fullLabel = _fullLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = BANYAN_WHITE_COLOR;
        self.layer.cornerRadius = 8.0f;
        self.layer.shadowOffset = CGSizeMake(5, 2);
        self.layer.shadowRadius = 3;
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        self.layer.shadowColor = [BANYAN_DARKGRAY_COLOR CGColor];
        
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.clipsToBounds = YES;
        [self addSubview:_imageView];
        
        _titleLabel = [[BNLabel alloc] initWithFrame:CGRectZero];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.minimumScaleFactor = 0.7;
        _titleLabel.numberOfLines = 0;
        _titleLabel.font = [UIFont fontWithName:@"Roboto-Medium" size:12];
        _titleLabel.textColor = BANYAN_BLACK_COLOR;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.verticalTextAlignment = BNLabelVerticalTextAlignmentBottom;
        [_imageView addSubview:_titleLabel];
        
        _authorLabel = [[BNLabel alloc] initWithFrame:CGRectZero];
        _authorLabel.backgroundColor = [UIColor clearColor];
        _authorLabel.font = [UIFont fontWithName:@"Roboto" size:10];
        _authorLabel.numberOfLines = 2;
        _authorLabel.textAlignment = NSTextAlignmentCenter;
        _authorLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _authorLabel.textColor = BANYAN_DARKGRAY_COLOR;
        _authorLabel.verticalTextAlignment = BNLabelVerticalTextAlignmentTop;
        [_imageView addSubview:_authorLabel];
        
        _fullLabel = [[BNLabel alloc] initWithFrame:self.bounds];
        _fullLabel.backgroundColor = BANYAN_GREEN_COLOR;
        _fullLabel.numberOfLines = 2;
        _fullLabel.textAlignment = NSTextAlignmentCenter;
        _fullLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:16];
        _fullLabel.textEdgeInsets = UIEdgeInsetsMake(TEXT_INSETS, TEXT_INSETS, TEXT_INSETS, TEXT_INSETS);
        _fullLabel.textColor = BANYAN_WHITE_COLOR;
        _fullLabel.layer.cornerRadius = 8.0f;
        [self addSubview:_fullLabel];
    }
    return self;
}

- (void)setStory:(Story *)story
{
    CGRect frame;
    CGSize expectedSize;
    
    self.imageView.hidden = NO;
    self.fullLabel.hidden = YES;
    
    // Image
    Media *imageMedia = [Media getMediaOfType:@"image" inMediaSet:story.media];
    if (imageMedia) {
        if ([imageMedia.remoteURL length]) {
            __weak UIImageView *wImageViewself = self.imageView;
            [self.imageView setImageWithURL:[NSURL URLWithString:imageMedia.remoteURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                UIImage *imageWithEffect = [image applyExtraLightEffect];
                wImageViewself.image = imageWithEffect;
            }];
        } else if ([imageMedia.localURL length]) {
            ALAssetsLibrary *library =[[ALAssetsLibrary alloc] init];
            [library assetForURL:[NSURL URLWithString:imageMedia.localURL] resultBlock:^(ALAsset *asset) {
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                CGImageRef imageRef = [rep fullScreenImage];
                UIImage *image = [[UIImage imageWithCGImage:imageRef] applyExtraLightEffect];
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
    
    // Story title
    frame.origin = CGPointMake(TEXT_INSETS, VIEW_INSETS);
    frame.size = CGSizeMake(CGRectGetWidth(self.bounds)-2*TEXT_INSETS, CGRectGetHeight(self.bounds)*0.7);
    expectedSize = [story.title boundingRectWithSize:frame.size
                                             options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                          attributes:@{NSFontAttributeName:self.titleLabel.font}
                                             context:nil].size;
    frame.size.height = ceilf(expectedSize.height);
    self.titleLabel.frame = frame;
    self.titleLabel.text = story.title;
    
    // Story author
    frame.origin = CGPointMake(TEXT_INSETS, CGRectGetMaxY(self.titleLabel.frame));
    frame.size.height = CGRectGetHeight(self.frame) - CGRectGetHeight(self.titleLabel.frame);
    self.authorLabel.frame = frame;
    self.authorLabel.text = [story shortStringOfContributors];
}

- (void)displayAsAddStoryButton
{
    [self.imageView cancelCurrentImageLoad];
    self.imageView.hidden = YES;
    self.fullLabel.hidden = NO;
    self.fullLabel.text = @"Create a new story";
}

#undef TEXT_INSETS
#undef VIEW_INSETS
@end

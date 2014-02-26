//
//  SingleImagePickerButton.m
//  Banyan
//
//  Created by Devang Mundhra on 8/5/13.
//
//

#import "SingleImagePickerButton.h"
#import "BNImageCropperViewController.h"
#import "BanyanAppDelegate.h"
#import "UIImage+ResizeAdditions.h"
#import "CMPopTipView.h"

@interface SingleImagePickerButton ()
@property (nonatomic, strong) UIButton *button;
@property (strong, nonatomic) UIView *imageView;
@property (strong, nonatomic) UIButton *imageDeleteButton;
@property (strong, nonatomic) UIButton *galleryButton;
@property (strong, nonatomic) UIImageView *imageDisplayView;
@property (strong, nonatomic) UIButton *thumbnailButton;
@property (nonatomic) BOOL imageLoaded;
@property (strong, nonatomic) Media *media;
@end

@implementation SingleImagePickerButton

@synthesize button;
@synthesize imageView;
@synthesize imageDeleteButton = _imageDeleteButton;
@synthesize galleryButton = _galleryButton;
@synthesize imageLoaded = _imageLoaded;
@synthesize media = _media;
@synthesize imageDisplayView = _imageDisplayView;
@synthesize thumbnailButton = _thumbnailButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    CGFloat white = 1;
    CGFloat alpha = 1;
    [backgroundColor getWhite:&white alpha:&alpha];
    
    [super setBackgroundColor:backgroundColor];
    [self.button setBackgroundColor:[self.button.backgroundColor colorWithAlphaComponent:alpha]];
    [self.galleryButton setBackgroundColor:[self.galleryButton.backgroundColor colorWithAlphaComponent:alpha]];
}

- (void)setImageLoaded:(BOOL)imageLoaded
{
    _imageLoaded = imageLoaded;
    if (imageLoaded) {
        self.button.hidden = YES;
        self.galleryButton.hidden = YES;
        self.imageView.hidden = NO;
        self.imageDeleteButton.hidden = NO;
    } else {
        self.button.hidden = NO;
        self.galleryButton.hidden = NO;
        self.imageView.hidden = YES;
        self.imageDeleteButton.hidden = YES;
        [self.thumbnailButton removeFromSuperview];
        self.thumbnailButton = nil;
    }
}

- (void) setup
{
    CGRect frame = self.bounds;
    self.clipsToBounds = YES;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // Add image button
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = frame;
        [button.titleLabel setFont:[UIFont boldSystemFontOfSize:15.0f]];
        [button setBackgroundColor:BANYAN_GREEN_COLOR];
        [button setImage:[UIImage imageNamed:@"cameraSymbol"] forState:UIControlStateNormal];
        [button setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
        [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [button setAdjustsImageWhenHighlighted:NO];
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        button.showsTouchWhenHighlighted = YES;
        [self addSubview:button];
        
        // Show photo gallery button
        frame.size = CGSizeMake(100.0f, 44.0f);
        frame.origin = CGPointMake(CGRectGetMaxX(self.bounds)-CGRectGetWidth(frame), CGRectGetMidY(self.bounds)-CGRectGetHeight(frame)/2);
        self.galleryButton = [[UIButton alloc] initWithFrame:frame];
        [self.galleryButton setTitle:@"Gallery" forState:UIControlStateNormal];
        [self.galleryButton setTitleColor:BANYAN_WHITE_COLOR forState:UIControlStateNormal];
        [self.galleryButton setBackgroundColor:BANYAN_DARKGRAY_COLOR];
        self.galleryButton.showsTouchWhenHighlighted = YES;
        [self addSubview:self.galleryButton];
    } else {
        self.galleryButton = [[UIButton alloc] initWithFrame:frame];
        [self.galleryButton setBackgroundColor:BANYAN_GREEN_COLOR];
        [self.galleryButton setTitleColor:BANYAN_WHITE_COLOR forState:UIControlStateNormal];
        [self.galleryButton setTitle:@"Photos" forState:UIControlStateNormal];
        self.galleryButton.showsTouchWhenHighlighted = YES;
        [self addSubview:self.galleryButton];
    }
    
    // Image view
    frame = self.bounds;
    self.imageView = [[UIView alloc] initWithFrame:frame];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
    [self addSubview:imageView];
    
    // Delete photo button
    frame.size = CGSizeMake(20.0f, 20.0f);
    frame.origin = CGPointMake(5.0f, 5.0f);
    self.imageDeleteButton = [[UIButton alloc] initWithFrame:frame];
    [self.imageDeleteButton setImage:[UIImage imageNamed:@"x_alt"] forState:UIControlStateNormal];
    [self.imageDeleteButton setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    self.imageDeleteButton.userInteractionEnabled = YES;
    [self.imageView addSubview:self.imageDeleteButton];
    
    frame = self.bounds;
    frame.origin.x = CGRectGetMaxX(self.imageDeleteButton.frame);
    frame.size.width -= frame.origin.x;
    self.imageDisplayView = [[UIImageView alloc] initWithFrame:frame];
    self.imageDisplayView.userInteractionEnabled = NO;
    self.imageDisplayView.contentMode = UIViewContentModeScaleAspectFit;
    [self.imageView addSubview:self.imageDisplayView];
    
    self.imageLoaded = NO;
}

#pragma mark -
#pragma mark Instance Methods

- (void) addTargetForCamera:(id)target action:(SEL)action
{
    [self.button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void) addTargetForPhotoGallery:(id)target action:(SEL)action
{
    [self.galleryButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void) addTargetToDeleteImage:(id)target action:(SEL)action
{
    [self.imageDeleteButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)editThumbnailButtonPressed:(id)sender
{
    BNImageCropperViewController *imageEditorVc = [[BNImageCropperViewController alloc] initWithNibName:@"BNImageCropperViewController" bundle:nil];
    imageEditorVc.sourceImage = self.imageDisplayView.image;
    imageEditorVc.previewImage = imageEditorVc.sourceImage;
    __weak BNImageCropperViewController *wImageEditorVc = imageEditorVc;
    imageEditorVc.doneCallback = ^(UIImage *editedImage, BOOL canceled){
        if (!canceled) {
            NSLog(@"Size of edited image is %@", NSStringFromCGSize(editedImage.size));
            [self.thumbnailButton setBackgroundImage:editedImage forState:UIControlStateNormal];
            self.media.thumbnail = editedImage;
        }
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [wImageEditorVc dismissViewControllerAnimated:YES completion:nil];
    };
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [[APP_DELEGATE topMostController] presentViewController:imageEditorVc animated:YES completion:nil];
}

- (void) setThumbnail:(UIImage *)image forMedia:(Media *)media
{
    NSAssert(self.imageDisplayView.image, @"No image when setting thumbnail");
    self.media = media;
    
#define BUTTON_SPACING 10
#define THUMBNAIL_BUTTON_SIZE 100
    CGRect frame = self.imageView.bounds;
    frame.origin.x = CGRectGetMaxX(self.imageDeleteButton.frame) + BUTTON_SPACING;
    frame.size.width = CGRectGetWidth(self.imageView.frame) - 2*BUTTON_SPACING - THUMBNAIL_BUTTON_SIZE - frame.origin.x;
    self.imageDisplayView.frame = frame;
    
    self.thumbnailButton = [UIButton buttonWithType:UIButtonTypeCustom];
    frame = self.imageDisplayView.frame;
    frame.origin.x = CGRectGetMaxX(self.imageDisplayView.frame)+BUTTON_SPACING;
    frame.origin.y = BUTTON_SPACING;
    frame.size.width = THUMBNAIL_BUTTON_SIZE;
    // Keep the aspect ratio the same
    frame.size.height = roundf((frame.size.width * MEDIA_THUMBNAIL_SIZE.height)/MEDIA_THUMBNAIL_SIZE.width);
    self.thumbnailButton.frame = frame;
    
    [self.thumbnailButton setBackgroundImage:image forState:UIControlStateNormal];
    self.thumbnailButton.imageEdgeInsets = UIEdgeInsetsMake(-10, 0, 0, 0);
    [self.thumbnailButton addTarget:self action:@selector(editThumbnailButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.thumbnailButton.titleEdgeInsets = UIEdgeInsetsMake(CGRectGetHeight(frame)+2*BUTTON_SPACING, 0, 0, 0);
    self.thumbnailButton.titleLabel.numberOfLines = 2;
    NSAttributedString *attrString = [[NSAttributedString alloc]
                                      initWithString:@"Edit thumbnail"
                                      attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Roboto" size:13],
                                                   NSForegroundColorAttributeName: BANYAN_GRAY_COLOR}];
    [self.thumbnailButton setAttributedTitle:attrString
                                    forState:UIControlStateNormal];
    [self.imageView addSubview:self.thumbnailButton];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *firstTimeDict = [[defaults dictionaryForKey:BNUserDefaultsFirstTimeActionsDict] mutableCopy];
    if (![firstTimeDict objectForKey:BNUserDefaultsFirstTimeModifyPieceImageAdded] ) {
        [firstTimeDict setObject:[NSNumber numberWithBool:YES] forKey:BNUserDefaultsFirstTimeModifyPieceImageAdded];
        [defaults setObject:firstTimeDict forKey:BNUserDefaultsFirstTimeActionsDict];
        [defaults synchronize];
        CMPopTipView *popTipView = [[CMPopTipView alloc] initWithTitle:@"Why thumbnails?"
                                                               message:@"Thumbnails helps us show the important parts of the image when a user is quickly scrolling through all the pieces"];
        SET_CMPOPTIPVIEW_APPEARANCES(popTipView);
        [popTipView presentPointingAtView:self.thumbnailButton inView:self.superview animated:NO];
    }
    
#undef BUTTON_SPACING
#undef THUMBNAIL_BUTTON_SIZE
}

- (void) setImage:(UIImage *)image
{
    CGRect frame = self.imageView.bounds;
    frame.origin.x = CGRectGetMaxX(self.imageDeleteButton.frame);
    frame.size.width -= frame.origin.x;
    self.imageDisplayView.frame = frame;
    
    [self.imageDisplayView cancelImageRequestOperation];
    [self.imageDisplayView setImage:image];
    self.imageLoaded = YES;
}

- (void) unsetImage
{
    [self.imageDisplayView cancelImageRequestOperation];
    [self.imageDisplayView setImageWithURL:nil];
    self.media = nil;
    self.imageLoaded = NO;
}

@end
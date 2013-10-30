//
//  SingleImagePickerButton.m
//  Banyan
//
//  Created by Devang Mundhra on 8/5/13.
//
//

#import "SingleImagePickerButton.h"

@interface SingleImagePickerButton ()
@property (nonatomic, strong) UIButton *button;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIButton *imageDeleteButton;
@property (strong, nonatomic) UIButton *galleryButton;
@property (nonatomic) BOOL imageLoaded;

- (void) setup;
@end

@implementation SingleImagePickerButton

@synthesize button;
@synthesize imageView;
@synthesize imageDeleteButton = _imageDeleteButton;
@synthesize galleryButton = _galleryButton;
@synthesize imageLoaded = _imageLoaded;

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
        [self addSubview:self.galleryButton];
    } else {
        self.galleryButton = [[UIButton alloc] initWithFrame:frame];
        [self.galleryButton setBackgroundColor:BANYAN_GREEN_COLOR];
        [self.galleryButton setTitleColor:BANYAN_WHITE_COLOR forState:UIControlStateNormal];
        [self.galleryButton setTitle:@"Photos" forState:UIControlStateNormal];
        [self addSubview:self.galleryButton];
    }
    
    // Image view
    frame = self.bounds;
    self.imageView = [[UIImageView alloc] initWithFrame:frame];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
    [self addSubview:imageView];
    
    // Delete photo button
    frame.size = CGSizeMake(20.0f, 20.0f);
    frame.origin = CGPointMake(5.0f, 5.0f);
    self.imageDeleteButton = [[UIButton alloc] initWithFrame:frame];
    [self.imageDeleteButton setBackgroundColor:BANYAN_RED_COLOR];
    [self.imageDeleteButton setTitle:@"X" forState:UIControlStateNormal];
    self.imageDeleteButton.clipsToBounds = YES;
    [self.imageDeleteButton.layer setCornerRadius:10.0f];
    self.imageDeleteButton.userInteractionEnabled = YES;
    [self.imageView addSubview:self.imageDeleteButton];
    
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

- (void) setImage:(UIImage *)image
{
    [self.imageView cancelImageRequestOperation];
    [self.imageView setImage:image];
    self.imageLoaded = YES;
}

- (void) unsetImage
{
    [self.imageView cancelImageRequestOperation];
    [self.imageView setImageWithURL:nil];
    self.imageLoaded = NO;
}

@end
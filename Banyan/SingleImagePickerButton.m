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
- (void) setup;
@end

@implementation SingleImagePickerButton

@synthesize button, delegate;
@synthesize imageView;

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

- (void) setup
{
    self.clipsToBounds = YES;
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = self.bounds;
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:15.0f]];
    [button addTarget:self action:@selector(handleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:BANYAN_GREEN_COLOR];
    [button setImage:[UIImage imageNamed:@"cameraSymbol"] forState:UIControlStateNormal];
    [button setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [button setAdjustsImageWhenHighlighted:NO];
    
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.showsTouchWhenHighlighted = YES;
    
    [self addSubview:button];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:imageView];
}

#pragma mark -
#pragma mark Instance Methods

- (void)handleButtonTapped:(id)sender {
    if (delegate) {
        [delegate singleImagePickerButtonTapped:self];
    }
}


@end
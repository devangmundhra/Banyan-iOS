//
//  MediaPickerButton.m
//  Banyan
//
//  Created by Devang Mundhra on 4/1/13.
//
//

#import "MediaPickerButton.h"

@interface MediaPickerButton ()
@property (nonatomic, strong) UIButton *button;
- (void) setup;
@end

@implementation MediaPickerButton
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
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = self.bounds;
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:15.0f]];
    [button setTitle:@"+ Photo" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(handleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:BANYAN_GREEN_COLOR];
    //    [button setImage:[UIImage imageNamed:@"sidebar_camera"] forState:UIControlStateNormal];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 12.0f, 0.0f, 10.0f)];
    [button setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 8.0f, 0.0f, 0.0f)];
    [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [button setAdjustsImageWhenHighlighted:NO];
    
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.showsTouchWhenHighlighted = YES;
    
    [self addSubview:button];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:imageView];
}

#pragma mark -
#pragma mark Instance Methods

- (void)handleButtonTapped:(id)sender {
    if (delegate) {
        [delegate mediaPickerButtonTapped:self];
    }
}

@end
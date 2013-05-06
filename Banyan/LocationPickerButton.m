//
//  LocationPickerButton.m
//  Banyan
//
//  Created by Devang Mundhra on 3/30/13.
//
//

#import "LocationPickerButton.h"

@interface LocationPickerButton () 

@property (nonatomic, strong) UIButton *nameButton;
@property (nonatomic, strong) UIButton *onOffButton;
@property (nonatomic, strong) id <FBGraphPlace> location;

- (void)setup;

@end

@implementation LocationPickerButton
@synthesize nameButton, delegate, location, onOffButton;

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
    CGRect bounds = self.bounds;
    // Location ON/OFF button
    self.onOffButton = [UIButton buttonWithType:UIButtonTypeCustom];
    onOffButton.frame = CGRectMake(bounds.origin.x, bounds.origin.y, 35.0f, bounds.size.height);
    [onOffButton.titleLabel setFont:[UIFont boldSystemFontOfSize:15.0f]];
    //    [onOffButton setBackgroundImage:[[UIImage imageNamed:@"SidebarToolbarButton"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0] forState:UIControlStateNormal];
    //    [onOffButton setBackgroundImage:[[UIImage imageNamed:@"SidebarToolbarButtonHighlighted"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0] forState:UIControlStateHighlighted];
    [onOffButton setTitle:@"+" forState:UIControlStateNormal];
    [onOffButton addTarget:self action:@selector(handleOnOffButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [onOffButton setBackgroundColor:BANYAN_GREEN_COLOR];
    //    [nameButton setImage:[UIImage imageNamed:@"sidebar_camera"] forState:UIControlStateNormal];
    [onOffButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 12.0f, 0.0f, 10.0f)];
    [onOffButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 8.0f, 0.0f, 0.0f)];
    [onOffButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [onOffButton setAdjustsImageWhenHighlighted:NO];
    
    onOffButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self addSubview:onOffButton];
    
    // Name Buttong
    self.nameButton = [UIButton buttonWithType:UIButtonTypeCustom];
    nameButton.frame = CGRectMake(bounds.origin.x + 35.0f, bounds.origin.y, bounds.size.width - self.onOffButton.frame.size.width, bounds.size.height);
    [nameButton.titleLabel setFont:[UIFont fontWithName:@"Roboto-Condensed" size:15]];
    nameButton.titleLabel.minimumFontSize = 10;
//    [nameButton setBackgroundImage:[[UIImage imageNamed:@"SidebarToolbarButton"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0] forState:UIControlStateNormal];
//    [nameButton setBackgroundImage:[[UIImage imageNamed:@"SidebarToolbarButtonHighlighted"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:0.0] forState:UIControlStateHighlighted];
    [nameButton setTitle:@"Add Location" forState:UIControlStateNormal];
    [nameButton addTarget:self action:@selector(handleNameButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [nameButton setBackgroundColor:BANYAN_BROWN_COLOR];
//    [nameButton setImage:[UIImage imageNamed:@"sidebar_camera"] forState:UIControlStateNormal];
    [nameButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 12.0f, 0.0f, 10.0f)];
    [nameButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 8.0f, 0.0f, 0.0f)];
    [nameButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [nameButton setAdjustsImageWhenHighlighted:NO];
    
    nameButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self addSubview:nameButton];
}

#pragma mark -
#pragma mark Instance Methods

- (void)handleNameButtonTapped:(id)sender {
    if (delegate) {
        [delegate locationPickerButtonTapped:self];
    }
}

- (void)handleOnOffButtonTapped:(id)sender {
    if (delegate) {
        [delegate locationPickerButtonToggleLocationEnable:self];
    }
}

- (void)locationPickerLocationUpdatedWithLocation:(id <FBGraphPlace>)newLocation
{
    location = newLocation;
    [nameButton setTitle:location.name forState:UIControlStateNormal];
}

- (void)locationPickerLocationEnabled:(BOOL)enable
{
    if (enable) {
        [onOffButton setTitle:@"x" forState:UIControlStateNormal];
    } else {
        [onOffButton setTitle:@"+" forState:UIControlStateNormal];
        [nameButton setTitle:@"Add Location" forState:UIControlStateNormal];
    }
}

- (void)setLocationPickerTitle:(NSString *)locationString
{
    [nameButton setTitle:locationString forState:UIControlStateNormal];
}

- (void)setEnabled:(BOOL)enable
{
    [nameButton setEnabled:enable];
    [onOffButton setEnabled:enable];
    if (!enable) {
        nameButton.alpha = onOffButton.alpha = 0.5;
    } else {
        nameButton.alpha = onOffButton.alpha = 1;
    }
}

- (BOOL)getEnabledState
{
    if ([onOffButton.titleLabel.text isEqualToString:@"x"]) {
        return YES;
    } else {
        return NO;
    }
}

@end

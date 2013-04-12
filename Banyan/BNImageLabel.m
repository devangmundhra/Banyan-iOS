//
//  BNImageLabel.m
//  Banyan
//
//  Created by Devang Mundhra on 4/10/13.
//
//

#import "BNImageLabel.h"

@implementation BNImageLabel

@synthesize imageView = _imageView;
@synthesize label = _label;

- (id)initWithFrameAtOrigin:(CGPoint)origin imageViewSize:(CGSize)imageViewSize labelSize:(CGSize)labelSize
{
#define SPACE_BETWEEN_IMAGE_AND_LABEL 5.0f

    CGRect frame = CGRectZero;
    frame.origin = origin;
    
    // height should be the max of both heights
    CGFloat height = MAX(imageViewSize.height, labelSize.height);
    CGFloat width = imageViewSize.width + labelSize.width;
    imageViewSize.height = labelSize.height = frame.size.height = height;
    frame.size.width = width;
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        CGRect imageViewFrame = CGRectZero;
        imageViewFrame.origin = CGPointMake(0,0);
        imageViewFrame.size = imageViewSize;
        self.imageView = [[UIImageView alloc] initWithFrame:imageViewFrame];
        self.imageView.contentMode = UIViewContentModeCenter;
        self.imageView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.imageView];
        
        CGRect labelFrame = CGRectZero;
        labelFrame.origin.x = imageViewSize.width + SPACE_BETWEEN_IMAGE_AND_LABEL;
        labelFrame.origin.y = 0;
        labelSize.width -= SPACE_BETWEEN_IMAGE_AND_LABEL;
        labelFrame.size = labelSize;
        self.label = [[UILabel alloc] initWithFrame:labelFrame];
        self.label.backgroundColor = [UIColor clearColor];
        [self addSubview:self.label];
    }
    return self;
}

@end

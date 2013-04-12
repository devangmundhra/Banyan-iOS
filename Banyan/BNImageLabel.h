//
//  BNImageLabel.h
//  Banyan
//
//  Created by Devang Mundhra on 4/10/13.
//
//
// Label with image on left side and label on right
#import <UIKit/UIKit.h>

@interface BNImageLabel : UIView

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *label;

- (id)initWithFrameAtOrigin:(CGPoint)origin imageViewSize:(CGSize)imageViewSize labelSize:(CGSize)labelSize;

@end

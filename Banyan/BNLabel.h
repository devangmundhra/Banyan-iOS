//
//  BNLabel.h
//  Banyan
//
//  Created by Devang Mundhra on 10/28/13.
//
//

#import <UIKit/UIKit.h>

/**
 The vertical alignment of text within a label.
 */
typedef enum {
    /** Aligns the text vertically at the top in the label (the default). */
    BNLabelVerticalTextAlignmentTop = UIControlContentVerticalAlignmentTop,
    
    /** Aligns the text vertically in the center of the label. */
    BNLabelVerticalTextAlignmentMiddle = UIControlContentVerticalAlignmentCenter,
    
    /** Aligns the text vertically at the bottom in the label. */
    BNLabelVerticalTextAlignmentBottom = UIControlContentVerticalAlignmentBottom
} BNLabelVerticalTextAlignment;

/**
 Simple label subclass that adds the ability to align your text to the top or bottom.
 */
@interface BNLabel : UILabel

/**
 The vertical text alignment of the receiver.
 
 The default is `SSLabelVerticalTextAlignmentMiddle` to match `UILabel`.
 */
@property (nonatomic, assign) BNLabelVerticalTextAlignment verticalTextAlignment;

/**
 The edge insets of the text.
 
 The default is `UIEdgeInsetsZero` so it behaves like `UILabel` by default.
 */
@property (nonatomic, assign) UIEdgeInsets textEdgeInsets;

@end

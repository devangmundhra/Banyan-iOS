//
//  BNTextField.m
//  Banyan
//
//  Created by Devang Mundhra on 10/28/13.
//
//

#import "BNTextField.h"

@interface BNTextField ()
- (void)_initialize;
@end

@implementation BNTextField

@synthesize textEdgeInsets = _textEdgeInsets;
@synthesize clearButtonEdgeInsets = _clearButtonEdgeInsets;
@synthesize placeholderTextColor = _placeholderTextColor;

- (void)setPlaceholderTextColor:(UIColor *)placeholderTextColor {
    _placeholderTextColor = placeholderTextColor;
    
    if (!self.text && self.placeholder) {
        [self setNeedsDisplay];
    }
}


#pragma mark - UIView

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self _initialize];
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _initialize];
    }
    return self;
}


#pragma mark - UITextField

- (CGRect)textRectForBounds:(CGRect)bounds {
    return UIEdgeInsetsInsetRect([super textRectForBounds:bounds], _textEdgeInsets);
}


- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}


- (CGRect)clearButtonRectForBounds:(CGRect)bounds {
    CGRect rect = [super clearButtonRectForBounds:bounds];
    rect.origin.x = rect.origin.x + _clearButtonEdgeInsets.right;
    rect.origin.y = rect.origin.y + _clearButtonEdgeInsets.top;
    return rect;
}


- (void)drawPlaceholderInRect:(CGRect)rect {
    if (!_placeholderTextColor) {
        [super drawPlaceholderInRect:rect];
        return;
    }
    
    [_placeholderTextColor setFill];
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paraStyle.alignment = self.textAlignment;
    [self.placeholder drawInRect:rect withAttributes:@{NSFontAttributeName: self.font,
                                                       NSParagraphStyleAttributeName: paraStyle}];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize superSize = [super sizeThatFits:size];
    return CGSizeMake(superSize.width+self.textEdgeInsets.left+self.textEdgeInsets.right,
                      superSize.height+self.textEdgeInsets.top+self.textEdgeInsets.bottom);
}

#pragma mark - Private

- (void)_initialize {
    _textEdgeInsets = UIEdgeInsetsZero;
    _clearButtonEdgeInsets = UIEdgeInsetsZero;
}

@end

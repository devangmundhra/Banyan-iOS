//
//  BNLabel.m
//  Banyan
//
//  Created by Devang Mundhra on 10/28/13.
//
//

#import "BNLabel.h"

@interface BNLabel ()
- (void)_initialize;
@end

@implementation BNLabel

@synthesize verticalTextAlignment = _verticalTextAlignment;

- (void)setVerticalTextAlignment:(BNLabelVerticalTextAlignment)verticalTextAlignment {
    _verticalTextAlignment = verticalTextAlignment;
    
    [self setNeedsLayout];
}

@synthesize textEdgeInsets = _textEdgeInsets;

- (void)setTextEdgeInsets:(UIEdgeInsets)textEdgeInsets {
    _textEdgeInsets = textEdgeInsets;
    
    [self setNeedsLayout];
}

#pragma mark - UIView

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self _initialize];
    }
    return self;
}


- (id)initWithFrame:(CGRect)aFrame {
    if ((self = [super initWithFrame:aFrame])) {
        [self _initialize];
    }
    return self;
}


#pragma mark - UILabel

- (void)drawTextInRect:(CGRect)rect {
    rect = UIEdgeInsetsInsetRect(rect, _textEdgeInsets);
    
    if (self.verticalTextAlignment == BNLabelVerticalTextAlignmentTop) {
        CGSize sizeThatFits = [super sizeThatFits:rect.size];
        rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, sizeThatFits.height);
    } else if (self.verticalTextAlignment == BNLabelVerticalTextAlignmentBottom) {
        CGSize sizeThatFits = [super sizeThatFits:rect.size];
        rect = CGRectMake(rect.origin.x, rect.origin.y + (rect.size.height - sizeThatFits.height), rect.size.width, sizeThatFits.height);
    }
    
    [super drawTextInRect:rect];
}


- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize superSize = [super sizeThatFits:size];
    return CGSizeMake(superSize.width+self.textEdgeInsets.left+self.textEdgeInsets.right,
                      superSize.height+self.textEdgeInsets.top+self.textEdgeInsets.bottom);
}

#pragma mark - Private

- (void)_initialize {
    self.verticalTextAlignment = BNLabelVerticalTextAlignmentMiddle;
    self.textEdgeInsets = UIEdgeInsetsZero;
}

@end

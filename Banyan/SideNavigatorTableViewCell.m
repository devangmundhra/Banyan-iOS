//
//  SideNavigatorTableViewCell.m
//  Banyan
//
//  Created by Devang Mundhra on 6/1/14.
//
//

#import "SideNavigatorTableViewCell.h"

CGFloat const SideNavigatorTableViewCellHeight = 40.0f;

@interface SideNavigatorTableViewCell ()
@property (strong, nonatomic) IBOutlet UIView *expansionView;

@end

@implementation SideNavigatorTableViewCell
@synthesize expansionView = _expansionView;
@synthesize titleLabel, arrowLabel;

- (void)setSelectionColor:(UIColor *)selectionColor
{
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    backgroundView.backgroundColor = selectionColor;
    
    [self setSelectedBackgroundView:backgroundView];
}

- (void)awakeFromNib
{
    // Initialization code
    self.arrowLabel.font = [UIFont fontWithName:@"FontAwesome" size:20];
    self.arrowLabel.textColor = BANYAN_WHITE_COLOR;

    self.titleLabel.font = [UIFont fontWithName:@"Roboto-Bold" size:15];
    self.titleLabel.textColor = BANYAN_LIGHTGRAY_COLOR;
    self.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setExpansionView:(UIView *)expansionView
{
    [_expansionView removeFromSuperview];
    _expansionView = expansionView;
    if (expansionView) {
        [self addSubview:expansionView];
    }
    CGRect frame = self.frame;
    frame.size.height = SideNavigatorTableViewCellHeight + CGRectGetHeight(expansionView.frame);
    self.frame = frame;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.expansionView) {
        CGRect frame = self.expansionView.frame;
        frame.origin.y = SideNavigatorTableViewCellHeight;
        self.expansionView.frame = frame;
    }
}
@end

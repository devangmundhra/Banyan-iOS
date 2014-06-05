//
//  SideNavigatorTableViewCell.h
//  Banyan
//
//  Created by Devang Mundhra on 6/1/14.
//
//

#import <UIKit/UIKit.h>

extern CGFloat const SideNavigatorTableViewCellHeight;

@interface SideNavigatorTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *arrowLabel;

- (void)setExpansionView:(UIView *)expansionView;
- (void)setSelectionColor:(UIColor *)selectionColor;

@end

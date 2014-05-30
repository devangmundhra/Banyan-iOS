//
//  InviteFriendCell.h
//  Banyan
//
//  Created by Devang Mundhra on 4/2/13.
//
//

#import <UIKit/UIKit.h>

@class InviteFriendCell;

@protocol InviteFriendCellDelegate <NSObject>

- (void) inviteFriendCellReadButtonTapped:(InviteFriendCell *)cell;
- (void) inviteFriendCellWriteButtonTapped:(InviteFriendCell *)cell;

@end

@interface InviteFriendCell : UITableViewCell

@property (strong, nonatomic) id<InviteFriendCellDelegate>delegate;

- (void) setFriend:(NSDictionary *)fbFriend;
- (void) enableReadButton:(BOOL)set;
- (void) enableWriteButton:(BOOL)set;
- (void) canRead:(BOOL)set;
- (void) canWrite:(BOOL)set;
- (void) hideReadWriteButtons:(BOOL)hide;
@end

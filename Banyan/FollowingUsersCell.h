//
//  FollowingUsersCell.h
//  Banyan
//
//  Created by Devang Mundhra on 9/3/12.
//
//

#import <UIKit/UIKit.h>

@class FollowingUsersCell;

@protocol FollowingUsersCellDelegate <NSObject>
@optional
/*!
 Sent to the delegate when a user button is tapped
 @param aUser the attributes of the user that was tapped
 */
- (void)cell:(FollowingUsersCell *)cellView didTapUserButton:(NSMutableDictionary *)aUser;
- (void)cell:(FollowingUsersCell *)cellView didTapFollowButton:(NSMutableDictionary *)aUser;

@end

@interface FollowingUsersCell : UITableViewCell

@property (nonatomic, weak) id<FollowingUsersCellDelegate> delegate;

/*! The user represented in the cell */
@property (nonatomic, strong) NSMutableDictionary *user;
@property (nonatomic, strong) UILabel *photoLabel;
@property (nonatomic, strong) UIButton *followButton;

/*! Setters for the cell's content */
- (void)setUser:(NSMutableDictionary *)user;

- (void)didTapUserButtonAction:(id)sender;
- (void)didTapFollowButtonAction:(id)sender;

/*! Static Helper methods */
+ (CGFloat)heightForCell;

@end

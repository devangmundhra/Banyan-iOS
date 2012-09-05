//
//  FollowingUsersCell.h
//  Banyan
//
//  Created by Devang Mundhra on 9/3/12.
//
//

#import <UIKit/UIKit.h>
#import "User_Defines.h"

@class FollowingUsersCell;

@protocol FollowingUsersCellDelegate <NSObject>
@optional
/*!
 Sent to the delegate when a user button is tapped
 @param aUser the attributes of the user that was tapped
 */
- (void)cell:(FollowingUsersCell *)cellView didTapUserButton:(NSDictionary *)aUser;
- (void)cell:(FollowingUsersCell *)cellView didTapFollowButton:(NSDictionary *)aUser;

@end

@interface FollowingUsersCell : UITableViewCell

@property (nonatomic, strong) id<FollowingUsersCellDelegate> delegate;

/*! The user represented in the cell */
@property (nonatomic, strong) NSDictionary *user;
@property (nonatomic, strong) UILabel *photoLabel;
@property (nonatomic, strong) UIButton *followButton;

/*! Setters for the cell's content */
- (void)setUser:(NSDictionary *)user;

- (void)didTapUserButtonAction:(id)sender;
- (void)didTapFollowButtonAction:(id)sender;

/*! Static Helper methods */
+ (CGFloat)heightForCell;

@end

//
//  BNNotificationsView.h
//  Banyan
//
//  Created by Devang Mundhra on 6/2/14.
//
//

#import <UIKit/UIKit.h>
#import "BNNotificationsTableViewCell.h"

@class BNNotificationsView;
@class Story, Piece, User;

@protocol BNNotificationsViewDelegate <NSObject>

- (void) notificationView:(BNNotificationsView *)notificationView didSelectStory:(Story *)story piece:(Piece *)piece;
- (void) notificationView:(BNNotificationsView *)notificationView didSelectUser:(User *)user;

@end

@interface BNNotificationsView : UIView
@property (strong, nonatomic) NSArray *notifications;
@property (nonatomic, weak) id<BNNotificationsViewDelegate> delegate;
@end
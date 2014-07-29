//
//  BNNotificationsTableViewCell.h
//  Banyan
//
//  Created by Devang Mundhra on 6/3/14.
//
//

#import <UIKit/UIKit.h>

extern NSString *const kBNNotificationTypeLike;
extern NSString *const kBNNotificationTypeFollow;
extern NSString *const kBNNotificationTypeJoin;
extern NSString *const kBNNotificationTypeStoryStart;
extern NSString *const kBNNotificationTypePieceAdded;
extern NSString *const kBNNotificationTypeViewInvite;
extern NSString *const kBNNotificationTypeContribInvite;

extern CGFloat const BNNotificationsTableViewCellHeight;

@interface BNNotificationsTableViewCell : UITableViewCell
@property (strong, nonatomic) NSDictionary *notification;

@end

//
//  BanyanConstants.h
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import <Foundation/Foundation.h>

#pragma mark - NSNotifications
extern NSString *const BNUserFollowingChangedNotification;
extern NSString *const BNUserLogInNotification;
extern NSString *const BNUserLogOutNotification;

#pragma mark - NSUserDefaults
extern NSString *const BNUserDefaultsFacebookFriends;
extern NSString *const BNUserDefaultsUserInfo;

#pragma mark - PFObject Story Class
// Class key
extern NSString *const kBNStoryClassKey;

#pragma mark - PFObject Scene Class
// Class key
extern NSString *const kBNSceneClassKey;

// Field keys
extern NSString *const kBNSceneIdKey;

#pragma mark - PFObject Activity Class

// Class key
extern NSString *const kBNActivityClassKey;

// Field keys
extern NSString *const kBNActivityTypeKey;
extern NSString *const kBNActivityFromUserKey;
extern NSString *const kBNActivityToUserKey;
extern NSString *const kBNActivitySceneKey;
extern NSString *const kBNActivityStoryKey;

// Type values
extern NSString *const kBNActivityTypeLike;
extern NSString *const kBNActivityTypeFollowUser;
extern NSString *const kBNActivityTypeFavourite;
extern NSString *const kBNActivityTypeView;
extern NSString *const kBNActivityTypeComment;
extern NSString *const kBNActivityTypeJoined;
//
//  BanyanConstants.h
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import <Foundation/Foundation.h>

#pragma mark - Push Notifications
extern NSString *const BNAddStoryInvitedContributePushNotification;
extern NSString *const BNAddStoryInvitedViewPushNotification;
extern NSString *const BNAddPieceToContributedStoryPushNotification;
extern NSString *const BNPieceActionPushNotification;
extern NSString *const BNUserFollowingPushNotification;
extern NSString *const BNPushNotificationChannelTypeSeperator;

#pragma mark - NSNotifications
extern NSString *const BNUserFollowingChangedNotification;
extern NSString *const BNUserLogInNotification;
extern NSString *const BNUserLogOutNotification;
extern NSString *const BNFBSessionStateChangedNotification;
// Notification called when new stories arrive or user permissions change
extern NSString *const BNStoryListRefreshedNotification;
// Notification called when some edit was done to the current list of stories (like delete/add piece)
extern NSString *const BNRefreshCurrentStoryListNotification;

#define UPDATE_STORY_LIST(_object_) [[NSNotificationCenter defaultCenter] postNotificationName:BNRefreshCurrentStoryListNotification object:_object_]

#pragma mark - NSUserDefaults
extern NSString *const BNUserDefaultsFacebookFriends;
extern NSString *const BNUserDefaultsUserInfo;
extern NSString *const BNUserDefaultsBanyanUsersFacebookFriends;
extern NSString *const BNUserDefaultsLastSuccessfulStoryUpdateTime;

extern NSString *const BNUserDefaultsAddStoryInvitedContributePushNotification;
extern NSString *const BNUserDefaultsAddStoryInvitedViewPushNotification;
extern NSString *const BNUserDefaultsAddPieceToContributedStoryPushNotification;
extern NSString *const BNUserDefaultsPieceActionPushNotification;
extern NSString *const BNUserDefaultsUserFollowingPushNotification;
#pragma mark - PFObject Story Class
// Class key
extern NSString *const kBNStoryClassKey;

// Dictionary keys for invitees
extern NSString *const kBNStoryPrivacyScope;
extern NSString *const kBNStoryPrivacyScopeInvited;
extern NSString *const kBNStoryPrivacyScopeLimited;
extern NSString *const kBNStoryPrivacyScopePublic;
extern NSString *const kBNStoryPrivacyInviteeList;
extern NSString *const kBNStoryPrivacyInvitedFacebookFriends;
extern NSString *const kBNStoryPrivacyInvitedBanyanFriends;

#pragma mark - ManagedObject Piece Class
// Class key
extern NSString *const kBNPieceClassKey;

// Field keys
extern NSString *const kBNPieceIdKey;

#pragma mark - ManagedObject Activity Class

// Class key
extern NSString *const kBNActivityClassKey;

// Field keys
extern NSString *const kBNActivityTypeKey;
extern NSString *const kBNActivityFromUserKey;
extern NSString *const kBNActivityToUserKey;
extern NSString *const kBNActivityPieceKey;
extern NSString *const kBNActivityStoryKey;

// Type values
extern NSString *const kBNActivityTypeLike;
extern NSString *const kBNActivityTypeUnlike;
extern NSString *const kBNActivityTypeFollowUser;
extern NSString *const kBNActivityTypeUnfollowUser;
extern NSString *const kBNActivityTypeFavourite;
extern NSString *const kBNActivityTypeUnfavourite;
extern NSString *const kBNActivityTypeView;
extern NSString *const kBNActivityTypeComment;
extern NSString *const kBNActivityTypeJoined;

#pragma mark - ManagedObject Media Class
// Class key
extern NSString *const kBNMediaClassKey;
typedef NS_ENUM(NSUInteger, MediaType) {
	kImage,
	kVideo
};

typedef NS_ENUM(NSUInteger, MediaResize) {
	kResizeSmall,
	kResizeMedium,
	kResizeLarge,
	kResizeOriginal
};

typedef NS_ENUM(NSUInteger, MediaOrientation) {
	kPortrait,
	kLandscape
};

#pragma mark - ManagedObject User Class
// Class key
extern NSString *const kBNUserClassKey;

#pragma mark - Colors
#define BANYAN_ORIG_GREEN_COLOR [UIColor colorWithRed:44/255.0 green:127/255.0 blue:84/255.0 alpha:1]
#define BANYAN_GREEN_COLOR [UIColor colorWithRed:71/255.0 green:114/255.0 blue:4/255.0 alpha:1]
#define BANYAN_DARK_GREEN_COLOR [UIColor colorWithRed:49/255.0 green:81/255.0 blue:3/255.0 alpha:1]
#define BANYAN_LIGHT_GREEN_COLOR [UIColor colorWithRed:113/255.0 green:154/255.0 blue:35/255.0 alpha:1]
#define BANYAN_BROWN_COLOR [UIColor colorWithRed:136/255.0 green:103/255.0 blue:68/255.0 alpha:1]
#define BANYAN_DARKGRAY_COLOR [UIColor colorWithRed:52/255.0 green:52/255.0 blue:52/255.0 alpha:1]
#define BANYAN_LIGHTGRAY_COLOR [UIColor colorWithRed:223/255.0 green:223/255.0 blue:223/255.0 alpha:1]
#define BANYAN_WHITE_COLOR [UIColor whiteColor]
#define BANYAN_BLACK_COLOR [UIColor blackColor]
#define BANYAN_PINK_COLOR [UIColor colorWithRed:229/255.0 green:56/255.0 blue:68/255.0 alpha:1]
#define BANYAN_RED_COLOR [UIColor colorWithRed:114/255.0 green:28/255.0 blue:16/255.0 alpha:1]
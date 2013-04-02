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
extern NSString *const BNFBSessionStateChangedNotification;
extern NSString *const BNStoryListRefreshedNotification;


#pragma mark - NSUserDefaults
extern NSString *const BNUserDefaultsFacebookFriends;
extern NSString *const BNUserDefaultsUserInfo;
extern NSString *const BNUserDefaultsBanyanUsersFacebookFriends;
extern NSString *const BNUserDefaultsLastSuccessfulStoryUpdateTime;

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

#pragma mark - PFObject Piece Class
// Class key
extern NSString *const kBNPieceClassKey;

// Field keys
extern NSString *const kBNPieceIdKey;

#pragma mark - PFObject Activity Class

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

#pragma mark - PFObject User Class
// Class key
extern NSString *const kBNUserClassKey;

#pragma mark - Colors
#define BANYAN_ORIG_GREEN_COLOR [UIColor colorWithRed:44/255.0 green:127/255.0 blue:84/255.0 alpha:1]
#define BANYAN_GREEN_COLOR [UIColor colorWithRed:71/255.0 green:114/255.0 blue:4/255.0 alpha:1]
#define BANYAN_BROWN_COLOR [UIColor colorWithRed:136/255.0 green:103/255.0 blue:68/255.0 alpha:1]
#define BANYAN_WHITE_COLOR [UIColor whiteColor]
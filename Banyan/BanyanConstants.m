//
//  BanyanConstants.m
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import "BanyanConstants.h"

#pragma mark - NSNotifications
NSString *const BNUserFollowingChangedNotification = @"io.banyan.Banyan:UserFollowingChangedNotification";
NSString *const BNUserLogInNotification = @"io.banyan.Banyan:UserLoginNotification";
NSString *const BNUserLogOutNotification = @"io.banyan.Banyan:UserLogoutNotification";
NSString *const BNFBSessionStateChangedNotification = @"io.banyan.Banyan:FBSessionStateChangedNotification";
NSString *const BNStoryListRefreshedNotification = @"io.banyan.Banyan:StoryListRefreshed";
NSString *const BNRefreshCurrentStoryListNotification = @"io.banyan.Banyan:RefreshCurrentStoryListNotification";

#pragma mark - NSUserDefaults
NSString *const BNUserDefaultsFacebookFriends = @"io.banyan.Banyan.userDefaults.facebookFriends";
NSString *const BNUserDefaultsUserInfo = @"io.banyan.Banyan.userDefaults.userInfo";
NSString *const BNUserDefaultsBanyanUsersFacebookFriends = @"io.banyan.Banyan.userDefaults.banyanUsersFacebookFriends";
NSString *const BNUserDefaultsLastSuccessfulStoryUpdateTime = @"io.banyan.Banyan.userDefaults.banyanLastSuccessfulUpdatedTime";

#pragma mark - ManagedObject Story Class
// Class key
NSString *const kBNStoryClassKey   = @"Story";

// Dictionary keys for invitees
NSString *const kBNStoryPrivacyScope = @"Scope";
NSString *const kBNStoryPrivacyScopeInvited = @"Invited";
NSString *const kBNStoryPrivacyScopeLimited = @"Limited";
NSString *const kBNStoryPrivacyScopePublic = @"Public";
NSString *const kBNStoryPrivacyInviteeList = @"InviteeList";
NSString *const kBNStoryPrivacyInvitedFacebookFriends = @"InvitedFacebookFriends";
NSString *const kBNStoryPrivacyInvitedBanyanFriends = @"InvitedBanyanFriends";

#pragma mark - ManagedObject Piece Class
// Class key
NSString *const kBNPieceClassKey = @"Piece";

// Field keys
NSString *const kBNPieceIdKey    = @"pieceId";

#pragma mark - ManagedObject Class
// Class key
NSString *const kBNActivityClassKey = @"Activity";

// Field keys
NSString *const kBNActivityTypeKey        = @"type";
NSString *const kBNActivityFromUserKey    = @"fromUser";
NSString *const kBNActivityToUserKey      = @"toUser";
NSString *const kBNActivityPieceKey       = @"pieceId";
NSString *const kBNActivityStoryKey       = @"storyId";

// Type values
NSString *const kBNActivityTypeLike       = @"like";
NSString *const kBNActivityTypeUnlike     = @"unlike";
NSString *const kBNActivityTypeFollowUser = @"followUser";
NSString *const kBNActivityTypeUnfollowUser = @"unfollowUser";
NSString *const kBNActivityTypeFavourite  = @"favourite";
NSString *const kBNActivityTypeUnfavourite  = @"unfavourite";
NSString *const kBNActivityTypeView       = @"view";
NSString *const kBNActivityTypeComment    = @"comment";
NSString *const kBNActivityTypeJoined     = @"joined";

#pragma mark - ManagedObject Media Class
// Class key
NSString *const kBNMediaClassKey           = @"Media";
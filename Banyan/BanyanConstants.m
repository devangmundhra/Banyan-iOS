//
//  BanyanConstants.m
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import "BanyanConstants.h"

#pragma mark - Push Notifications
NSString *const BNAddStoryInvitedContributePushNotification = @"addStoryInvitedContri";
NSString *const BNAddStoryInvitedViewPushNotification = @"addStoryInvitedView";
NSString *const BNAddPieceToContributedStoryPushNotification = @"addPieceToContriStory";
NSString *const BNPieceActionPushNotification = @"pieceAction";
NSString *const BNUserFollowingPushNotification = @"userFollowing";
NSString *const BNPushNotificationChannelTypeSeperator = @"_";

#pragma mark - NSNotifications
NSString *const BNUserFollowingChangedNotification = @"io.banyan.Banyan:UserFollowingChangedNotification";
NSString *const BNUserLogInNotification = @"io.banyan.Banyan:UserLoginNotification";
NSString *const BNUserLogOutNotification = @"io.banyan.Banyan:UserLogoutNotification";
NSString *const BNFBSessionStateChangedNotification = @"io.banyan.Banyan:FBSessionStateChangedNotification";
NSString *const BNStoryListRefreshedNotification = @"io.banyan.Banyan:StoryListRefreshed";
NSString *const BNRefreshCurrentStoryListNotification = @"io.banyan.Banyan:RefreshCurrentStoryListNotification";

#pragma mark - NSUserDefaults
NSString *const BNUserDefaultsUserInfo = @"io.banyan.Banyan.userDefaults.userInfo";
NSString *const BNUserDefaultsBanyanUsersFacebookFriends = @"io.banyan.Banyan.userDefaults.banyanUsersFacebookFriends";
NSString *const BNUserDefaultsMyFacebookFriends = @"io.banyan.Banyan.userDefaults.myFacebookFriends";
NSString *const BNUserDefaultsLastSuccessfulStoryUpdateTime = @"io.banyan.Banyan.userDefaults.banyanLastSuccessfulUpdatedTime";
NSString *const BNUserDefaultsLastGetRequestTime = @"io.banyan.Banyan.userDefaults.banyanLastGetRequestTime";

NSString *const BNUserDefaultsAddStoryInvitedContributePushNotification = @"io.banyan.Banyan.userDefaults.addStoryInvitedContrPushNotification";
NSString *const BNUserDefaultsAddStoryInvitedViewPushNotification = @"io.banyan.Banyan.userDefaults.addStoryInvitedViewPushNotification";
NSString *const BNUserDefaultsAddPieceToContributedStoryPushNotification = @"io.banyan.Banyan.userDefaults.addPieceToContriStoryPushNotification";
NSString *const BNUserDefaultsPieceActionPushNotification = @"io.banyan.Banyan.userDefaults.pieceActionPushNotification";
NSString *const BNUserDefaultsUserFollowingPushNotification = @"io.banyan.Banyan.userDefaults.userFollowingPushNotification";

NSString *const BNUserDefaultsUserPageTurnAnimation = @"io.banyan.Banyan.userDefaults.pageTurnAnimation";

NSString *const BNUserDefaultsCurrentOngoingStoryToContribute = @"io.banyan.Banyan.UserDefaults.currentOngoingStoryToContribute";

NSString *const BNUserDefaultsFirstTimeActionsDict = @"io.banyan.Banyan.UserDefaults.firstTimeActionsDict";
NSString *const BNUserDefaultsFirstTimeAppOpen = @"io.banyan.Banyan.UserDefaults.firstTime.AppOpen";
NSString *const BNUserDefaultsFirstTimeStoryListVCWoSignin = @"io.banyan.Banyan.UserDefaults.firstTime.storyListVCWoSignin";
NSString *const BNUserDefaultsFirstTimeStoryListVCWSignin = @"io.banyan.Banyan.UserDefaults.firstTime.storyListVCWSignin";
NSString *const BNUserDefaultsFirstTimeModifyPieceVCOpen = @"io.banyan.Banyan.UserDefaults.firstTime.modifyPieceVCOpen";
NSString *const BNUserDefaultsFirstTimeStoryReaderOpen = @"io.banyan.Banyan.UserDefaults.firstTime.storyReaderOpen";
NSString *const BNUserDefaultsFirstTimeModifyPieceImageAdded = @"io.banyan.Banyan.UserDefaults.firstTime.modifyPieceImageAdded";
NSString *const BNUserDefaultsFirstTimeSettingPermissions = @"io.banyan.Banyan.UserDefaults.firstTime.settingPermissions";
NSString *const BNUserDefaultsFirstTimeCreateStoryVCOpen = @"io.banyan.Banyan.UserDefaults.firstTime.createStoryVCOpen";

NSString *const BNUserDefaultsDeviceToken = @"io.banyan.Banyan.UserDefaults.deviceToken";

#pragma mark - ManagedObject Story Class
// Class key
NSString *const kBNStoryClassKey   = @"Story";

// Dictionary keys for invitees
NSString *const kBNStoryPrivacyScopeInvited = @"Invited";
NSString *const kBNStoryPrivacyScopeLimited = @"Limited";
NSString *const kBNStoryPrivacyScopePublic = @"Public";

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
NSString *const kBNActivityObjectKey      = @"object";

// Type values
NSString *const kBNActivityTypeLike       = @"like";
NSString *const kBNActivityTypeFollowUser = @"followUser";
NSString *const kBNActivityTypeUnfollowUser = @"unfollowUser";
NSString *const kBNActivityTypeFollowStory = @"followStory";
NSString *const kBNActivityTypeView       = @"view";
NSString *const kBNActivityTypeComment    = @"comment";
NSString *const kBNActivityTypeJoined     = @"joined";

#pragma mark - ManagedObject Media Class
// Class key
NSString *const kBNMediaClassKey           = @"Media";

#pragma mark - ManagedObject User Class
// Class key
NSString *const kBNUserClassKey           = @"User";

#pragma mark - Errors
NSString *const BNErrorDomain = @"com.banyan.Banyan.ErrorDomain";
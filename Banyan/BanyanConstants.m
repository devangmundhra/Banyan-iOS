//
//  BanyanConstants.m
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import "BanyanConstants.h"

#pragma mark - NSNotifications
NSString *const BNUserFollowingChangedNotification = @"io.banyan.Banyan.userFollowingChanged";
NSString *const BNUserLogInNotification = @"io.banyan.Banyan.userLogIn";
NSString *const BNUserLogOutNotification = @"io.banyan.Banyan.userLogOut";

#pragma mark - NSUserDefaults
NSString *const BNUserDefaultsFacebookFriends = @"io.banyan.Banyan.userDefaults.facebookFriends";
NSString *const BNUserDefaultsUserInfo = @"io.banyan.Banyan.userDefaults.userInfo";
NSString *const BNUserDefaultsBanyanUsersFacebookFriends = @"io.banyan.Banyan.userDefaults.banyanUsersFacebookFriends";

#pragma mark - PFObject Story Class
// Class key
NSString *const kBNStoryClassKey   = @"Story";

#pragma mark - PFObject Scene Class
// Class key
NSString *const kBNSceneClassKey = @"Scene";

// Field keys
NSString *const kBNSceneIdKey    = @"sceneId";

#pragma mark - Activity Class
// Class key
NSString *const kBNActivityClassKey = @"Activity";

// Field keys
NSString *const kBNActivityTypeKey        = @"type";
NSString *const kBNActivityFromUserKey    = @"fromUser";
NSString *const kBNActivityToUserKey      = @"toUser";
NSString *const kBNActivitySceneKey       = @"sceneId";
NSString *const kBNActivityStoryKey       = @"storyId";

// Type values
NSString *const kBNActivityTypeLike       = @"like";
NSString *const kBNActivityTypeFollowUser = @"followUser";
NSString *const kBNActivityTypeFavourite  = @"favourite";
NSString *const kBNActivityTypeView       = @"view";
NSString *const kBNActivityTypeComment    = @"comment";
NSString *const kBNActivityTypeJoined     = @"joined";
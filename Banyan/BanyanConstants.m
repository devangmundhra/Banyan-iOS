//
//  BanyanConstants.m
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import "BanyanConstants.h"

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
NSString *const kBNActivityTypeFollow     = @"follow";
NSString *const kBNActivityTypeFavourite  = @"favourite";
NSString *const kBNActivityTypeView       = @"view";
NSString *const kBNActivityTypeComment    = @"comment";
NSString *const kBNActivityTypeJoined     = @"joined";
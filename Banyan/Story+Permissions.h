//
//  Story+Permissions.h
//  Banyan
//
//  Created by Devang Mundhra on 12/31/12.
//
//

#import "Story.h"
#import "BNPermissionsObject.h"

@interface Story (Permissions)

// Permissions
- (NSString *)viewerPrivacyScope;
- (NSUInteger) numberOfViewers;
- (NSArray *) storyViewers;

- (NSString *)contributorPrivacyScope;
- (NSUInteger) numberOfContributors;
- (NSArray *)storyContributors;

- (NSString *)contributorPermissions;
- (NSString *)viewerPermissions;

// Actual contributors
- (NSString *)shortStringOfContributors;
- (NSArray *) arrayOfPieceContributors;

extern NSString *const kDictionaryInSortedArrayOfContributorsNameKey;
extern NSString *const kDictionaryInSortedArrayOfContributorsCountKey;
- (NSArray *) sortedArrayOfPieceContributorsWithCount;

@end

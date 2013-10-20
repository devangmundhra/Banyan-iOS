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

- (NSString *)viewerPrivacyScope;
- (NSUInteger) numberOfViewers;
- (NSArray *) storyViewers;

- (NSString *)contributorPrivacyScope;
- (NSUInteger) numberOfContributors;
- (NSArray *)storyContributors;

- (NSString *)shortStringOfContributors;

- (NSString *)contributorPermissions;
- (NSString *)viewerPermissions;

@end

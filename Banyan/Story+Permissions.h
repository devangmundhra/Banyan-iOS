//
//  Story+Permissions.h
//  Banyan
//
//  Created by Devang Mundhra on 12/31/12.
//
//

#import "Story.h"

@interface Story (Permissions)

- (void) resetPermission;
- (NSString *)viewerPrivacyScope;
- (NSUInteger) numberOfViewers;
- (NSArray *) storyViewers;

- (NSString *)contributorPrivacyScope;
- (NSUInteger) numberOfContributors;
- (NSArray *)storyContributors;

@end

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

// Actual contributors
- (NSString *)shortStringOfContributors;
- (NSArray *) arrayOfPieceContributors;

extern NSString *const kDictionaryInSortedArrayOfContributorsNameKey;
extern NSString *const kDictionaryInSortedArrayOfContributorsCountKey;
- (NSArray *) sortedArrayOfPieceContributorsWithCount;

@end

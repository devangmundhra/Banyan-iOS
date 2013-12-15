//
//  Story+Permissions.m
//  Banyan
//
//  Created by Devang Mundhra on 12/31/12.
//
//

#import "Story+Permissions.h"
#import "AFBanyanAPIClient.h"
#import "User.h"
#import "Piece.h"

NSString *const kDictionaryInSortedArrayOfContributorsNameKey = @"name";
NSString *const kDictionaryInSortedArrayOfContributorsCountKey = @"count";

@implementation Story (Permissions)

# pragma mark Permissions management
- (NSString *)contributorPermissions
{
    BNPermissionsObject *permissionObj = [BNPermissionsObject permissionObjectWithDictionary:self.writeAccess];
    return [NSString stringWithFormat:@"%@ can contribute to the story", [permissionObj stringifyPermissionObject]];
}

- (NSString *)viewerPermissions
{
    BNPermissionsObject *permissionObj = [BNPermissionsObject permissionObjectWithDictionary:self.readAccess];
    return [NSString stringWithFormat:@"%@ can view the story", [permissionObj stringifyPermissionObject]];
}

- (NSString *)contributorPrivacyScope
{
    NSDictionary *scopeDict = self.writeAccess;
    NSString *privacyScope = [scopeDict objectForKey:kBNStoryPrivacyScope];
    return privacyScope;
}

- (NSUInteger) numberOfContributors
{
    return [self storyContributors].count;
}

// Array of all contributors having permissions
- (NSArray *)storyContributors
{
    if ([[self contributorPrivacyScope] isEqualToString:kBNStoryPrivacyScopeInvited]) {
        NSDictionary *scopeDict = self.writeAccess;
        NSDictionary *contributorsInvited = [scopeDict objectForKey:kBNStoryPrivacyInviteeList];
        NSArray *invitedToContFBList = [contributorsInvited objectForKey:kBNStoryPrivacyInvitedFacebookFriends];
        NSArray *invitedToContBNList = [contributorsInvited objectForKey:kBNStoryPrivacyInvitedBanyanFriends];
        return [invitedToContFBList arrayByAddingObjectsFromArray:invitedToContBNList];
    }
    return nil;
}

- (NSString *)viewerPrivacyScope
{
    NSDictionary *scopeDict = self.readAccess;
    NSString *privacyScope = [scopeDict objectForKey:kBNStoryPrivacyScope];
    return privacyScope;
}

- (NSUInteger) numberOfViewers
{
    return [self storyViewers].count;
}

// Array of all viewers given permission
- (NSArray *) storyViewers
{
    if ([[self viewerPrivacyScope] isEqualToString:kBNStoryPrivacyScopeInvited]) {
        NSDictionary *scopeDict = self.readAccess;
        NSDictionary *viewersInvited = [scopeDict objectForKey:kBNStoryPrivacyInviteeList];
        NSArray *invitedToViewFBList = [viewersInvited objectForKey:kBNStoryPrivacyInvitedFacebookFriends];
        NSArray *invitedToViewBNList = [viewersInvited objectForKey:kBNStoryPrivacyInvitedBanyanFriends];
        return [invitedToViewFBList arrayByAddingObjectsFromArray:invitedToViewBNList];
    }
    return nil;
}

// Array of all contributors including author
- (NSArray *) arrayOfPieceContributors
{
    NSMutableArray *contributorArray = [NSMutableArray array];
    // Add author of story first
    [contributorArray addObject:REPLACE_NIL_WITH_EMPTY_STRING(self.author.name)];
    
    // Add other pieces first
    for (Piece *piece in self.pieces) {
        [contributorArray addObject:piece.author.name];
    }
    
    return [NSOrderedSet orderedSetWithArray:contributorArray].array;
}

// String of contributors separated by comma including author
- (NSString *)shortStringOfContributors
{
    return [[self arrayOfPieceContributors] componentsJoinedByString:@", "];
}

// Array of contributors sorted descending
- (NSArray *) sortedArrayOfPieceContributorsWithCount
{
    NSCountedSet *countedSet = [[NSCountedSet alloc] initWithCapacity:1];
    for (Piece *piece in self.pieces) {
        [countedSet addObject:piece.author.name];
    }
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:1];
    NSEnumerator *enumerator = [countedSet objectEnumerator];
    NSString *contributor = nil;
    
    while (contributor = [enumerator nextObject]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:contributor forKey:kDictionaryInSortedArrayOfContributorsNameKey];
        [dict setValue:[NSNumber numberWithUnsignedInteger:[countedSet countForObject:contributor]] forKey:kDictionaryInSortedArrayOfContributorsCountKey];
        [array addObject:dict];
    }
    
    NSSortDescriptor * countSortDescriptor = [[NSSortDescriptor alloc] initWithKey:kDictionaryInSortedArrayOfContributorsCountKey
                                                 ascending:NO];
    NSSortDescriptor * nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:kDictionaryInSortedArrayOfContributorsNameKey
                                                                         ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:countSortDescriptor, nameSortDescriptor, nil];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:sortDescriptors];
    
    return sortedArray;
}

@end

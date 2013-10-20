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

- (NSString *)shortStringOfContributors
{
    NSMutableArray *contributorArray = [NSMutableArray array];
    // Add author of story first
    [contributorArray addObject:REPLACE_NIL_WITH_EMPTY_STRING(self.author.name)];
    
    // Add other pieces first
    for (Piece *piece in self.pieces) {
        [contributorArray addObject:piece.author.name];
    }
    
    return [[NSOrderedSet orderedSetWithArray:contributorArray].array componentsJoinedByString:@", "];
}

@end

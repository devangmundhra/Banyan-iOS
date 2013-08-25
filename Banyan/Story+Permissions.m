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

@implementation Story (Permissions)

# pragma mark Permissions management
- (void) resetPermission
{
    assert(false);
//    self.isInvited = NO;
//    self.canContribute = NO;
//    self.canView = NO;
//    
//    if (![BNSharedUser currentUser]) {
//        NSLog(@"%s No current user", __PRETTY_FUNCTION__);
//    }
//    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"json", @"format", self.bnObjectId, @"object_id", [BNSharedUser currentUser].userId, @"user_id", nil];
//    
//    [[AFBanyanAPIClient sharedClient] getPath:BANYAN_API_GET_PERMISSIONS(@"Story")
//                                   parameters:parameters
//                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                                          NSDictionary *results = (NSDictionary *)responseObject;
//                                          self.canContribute = [[results objectForKey:@"write"] boolValue];
//                                          self.canView = [[results objectForKey:@"read"] boolValue];
//                                          self.isInvited = [[results objectForKey:@"invited"] boolValue];
//                                      }
//                                      failure:AF_BANYAN_ERROR_BLOCK()];
//    
//    return;
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

@end

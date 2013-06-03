//
//  Story+Permissions.m
//  Banyan
//
//  Created by Devang Mundhra on 12/31/12.
//
//

#import "Story+Permissions.h"
#import "AFBanyanAPIClient.h"
#import <Parse/Parse.h>

@implementation Story (Permissions)

# pragma mark Permissions management
- (void) resetPermission
{
    self.isInvited = NO;
    self.canContribute = NO;
    self.canView = NO;
    
    if (![PFUser currentUser]) {
        NSLog(@"%s No current user", __PRETTY_FUNCTION__);
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"json", @"format", self.bnObjectId, @"object_id", [PFUser currentUser].objectId, @"user_id", nil];
    
    [[AFBanyanAPIClient sharedClient] getPath:BANYAN_API_GET_PERMISSIONS(@"Story")
                                   parameters:parameters
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSDictionary *results = (NSDictionary *)responseObject;
                                          self.canContribute = [results objectForKey:@"write"];
                                          self.canView = [results objectForKey:@"read"];
                                          self.isInvited = [results objectForKey:@"invited"];
                                      }
                                      failure:AF_BANYAN_ERROR_BLOCK()];
    
    return;
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

//
//  BNPermissionsObject.m
//  Banyan
//
//  Created by Devang Mundhra on 10/18/13.
//
//

#import "BNPermissionsObject.h"

#define permissionVersionString @"1.0"

@interface BNPermissionsObject ()
@property (strong, nonatomic) NSMutableDictionary *dataObj;
@end

@implementation BNPermissionsObject
@synthesize dataObj = _dataObj;

- (id)init
{
    self = [super init];
    if (self) {
        _dataObj = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (BNPermissionsObject *)permissionObject
{
    BNPermissionsObject *permObj = [[BNPermissionsObject alloc] init];
    [permObj.dataObj setObject:permissionVersionString forKey:kBNPermssionsVersion];
    return permObj;
}

+ (BNPermissionsObject *)permissionObjectWithDictionary:(NSDictionary *)dictionary
{
    BNPermissionsObject *permObj = [[BNPermissionsObject alloc] init];
    [permObj.dataObj setDictionary:dictionary];
    [permObj.dataObj setObject:permissionVersionString forKey:kBNPermssionsVersion];
    return permObj;
}

- (NSDictionary *)permissionsDictionary
{
    return [self.dataObj copy];
}

- (NSString *)scope
{
    return [self.dataObj objectForKey:kBNStoryPrivacyScope];
}

- (void)setScope:(NSString *)scope
{
    [self.dataObj setObject:scope forKey:kBNStoryPrivacyScope];
}

- (NSMutableDictionary *)inviteeList
{
    if ([[self.dataObj allKeys] containsObject:kBNStoryPrivacyInviteeList])
        return [[self.dataObj objectForKey:kBNStoryPrivacyInviteeList] mutableCopy];
    else
        return [NSMutableDictionary dictionary];
}

- (void)setInviteeList:(NSMutableDictionary *)inviteeList
{
    if (inviteeList)
        [self.dataObj setObject:inviteeList forKey:kBNStoryPrivacyInviteeList];
    else
        [self.dataObj removeObjectForKey:kBNStoryPrivacyInviteeList];
}

- (NSMutableArray *)facebookInvitedList
{
    if ([[self.inviteeList allKeys] containsObject:kBNStoryPrivacyInvitedFacebookFriends])
        return [[self.inviteeList objectForKey:kBNStoryPrivacyInvitedFacebookFriends] mutableCopy];
    else
        return [NSMutableArray array];
}

- (void)setFacebookInvitedList:(NSMutableArray *)facebookInvitedList
{
    NSMutableDictionary *inviteeList = self.inviteeList;
    if (facebookInvitedList)
        [inviteeList setObject:facebookInvitedList forKey:kBNStoryPrivacyInvitedFacebookFriends];
    else
        [inviteeList removeObjectForKey:kBNStoryPrivacyInvitedFacebookFriends];
    self.inviteeList = inviteeList;
}

- (NSString *)stringifyPermissionObject
{
    if ([self.scope isEqualToString:kBNStoryPrivacyScopePublic]) {
        return @"Any one";
    } else if ([self.scope isEqualToString:kBNStoryPrivacyScopeLimited]) {
        // We invite friends of people in the invitee list
        NSUInteger lenghtOfFBInviteeList = self.facebookInvitedList.count;
        if (!lenghtOfFBInviteeList)
            return @"No one";
        
        NSMutableString *permissionStr = [NSMutableString stringWithFormat:@"Facebook friends of "];
        [self.facebookInvitedList enumerateObjectsUsingBlock:^(NSDictionary *invitee, NSUInteger idx, BOOL *stop) {
            [permissionStr appendString:[invitee objectForKey:@"name"]];
            if (lenghtOfFBInviteeList > 1) {
                if (idx + 1 == lenghtOfFBInviteeList - 1) {
                    [permissionStr appendString:@" and "];
                } else if (idx < lenghtOfFBInviteeList - 1) {
                    [permissionStr appendString:@" , "];
                }
            }
        }];
        return permissionStr;
    } else if ([self.scope isEqualToString:kBNStoryPrivacyScopeInvited]) {
        // We invite the people in the invite list
        NSUInteger lenghtOfFBInviteeList = self.facebookInvitedList.count;
        if (!lenghtOfFBInviteeList)
            return @"No one";
        
        NSMutableString *permissionStr = [NSMutableString string];
        [self.facebookInvitedList enumerateObjectsUsingBlock:^(NSDictionary *invitee, NSUInteger idx, BOOL *stop) {
            [permissionStr appendString:[invitee objectForKey:@"name"]];
            if (lenghtOfFBInviteeList > 1) {
                if (idx + 1 == lenghtOfFBInviteeList - 1) {
                    [permissionStr appendString:@" and "];
                } else if (idx < lenghtOfFBInviteeList - 1) {
                    [permissionStr appendString:@" , "];
                }
            }
        }];
        return permissionStr;
    } else {
        NSLog(@"Unknown story permission scope");
    }
    return @"No one";
}

- (NSString *)description
{
    return [self stringifyPermissionObject];
}

# pragma mark NSCopying Protocol
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [BNPermissionsObject permissionObjectWithDictionary:self.dataObj];
    return copy;
}
@end

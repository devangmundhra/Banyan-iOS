//
//  BNPermissionsObject.m
//  Banyan
//
//  Created by Devang Mundhra on 10/18/13.
//
//

#import "BNPermissionsObject.h"

#define permissionVersionNumber @1

@interface BNPermissionsObject (InternalMethods)

+ (NSString *)formattedPermissionObjectForPublic:(BNPermissionsObject <BNPermissionsObject>*)obj;
+ (NSString *)longFormattedPermissionObjectForAllFBFriendsOf:(BNPermissionsObject <BNPermissionsObject>*)obj
                                         middleSeperator:(NSString *)middleSeperator lastItemSeperator:(NSString *)lastItemSeperator;
+ (NSString *)longFormattedPermissionObjectForFBFriends:(BNPermissionsObject <BNPermissionsObject>*)obj
                                    middleSeperator:(NSString *)middleSeperator lastItemSeperator:(NSString *)lastItemSeperator;
+ (NSString *)shortFormattedPermissionObjectForAllFBFriendsOf:(BNPermissionsObject <BNPermissionsObject>*)obj;
+ (NSString *)shortFormattedPermissionObjectForFBFriends:(BNPermissionsObject <BNPermissionsObject>*)obj;
@end

@implementation BNPermissionsObject
@synthesize inviteeList;
@synthesize permissionsVersion;

+ (BNPermissionsObject <BNPermissionsObject> *)permissionsObject
{
    BNPermissionsObject<BNPermissionsObject> *obj = (BNPermissionsObject<BNPermissionsObject> *)[BNDuckTypedObject duckTypedObject];
    obj.permissionsVersion = permissionVersionNumber;
    obj.inviteeList = [BNPermissionsInviteeListObject permissionsInviteeListObject];
    return obj;
}

- (id)init
{
    self = [super init];
    if (self) {
        NSAssert(false, @"User [BNPermissionsObject permissionObject for new objects");
    }
    return self;
}


+ (NSString *)longFormattedPermissionObject:(BNPermissionsObject <BNPermissionsObject>*)obj level:(BNPermissionObjectInvitationLevel)level list:(BOOL)list
{
    NSString *middleSeperator = nil;
    NSString *lastSeperator = nil;
    NSString *localPermissionsStrPublic = nil;
    NSString *localPermissionStrAllFbOf = nil;
    NSString *localPermissionStrSelectedFb = nil;
    NSMutableString *permissionStr = nil;
    
    if (list) {
        middleSeperator = @"\r";
        lastSeperator = @"\r";
    } else {
        middleSeperator = @", ";
        lastSeperator = @" and ";
    }

    switch (level) {
        case BNPermissionObjectInvitationLevelPublic:
            return [self formattedPermissionObjectForPublic:obj];
            break;
            
        case BNPermissionObjectInvitationLevelFacebookFriendsOf:
            return [self longFormattedPermissionObjectForAllFBFriendsOf:obj middleSeperator:middleSeperator lastItemSeperator:lastSeperator];
            break;
            
        case BNPermissionObjectInvitationLevelSelectedFacebookFriends:
            return [self longFormattedPermissionObjectForFBFriends:obj middleSeperator:middleSeperator lastItemSeperator:lastSeperator];
            break;
            
        case BNPermissionObjectInvitationLevelAll:
            localPermissionsStrPublic = [self formattedPermissionObjectForPublic:obj];
            
            if (localPermissionsStrPublic) {
                return localPermissionsStrPublic;
            }
            
            localPermissionStrAllFbOf = [self longFormattedPermissionObjectForAllFBFriendsOf:obj middleSeperator:middleSeperator lastItemSeperator:lastSeperator];
            localPermissionStrSelectedFb = [self longFormattedPermissionObjectForFBFriends:obj middleSeperator:middleSeperator lastItemSeperator:lastSeperator];
            if (localPermissionStrAllFbOf || localPermissionStrSelectedFb) {
                if (localPermissionStrSelectedFb && localPermissionStrAllFbOf) {
                    permissionStr = [NSMutableString stringWithFormat:@"%@ including %@", localPermissionStrAllFbOf, localPermissionStrSelectedFb];
                } else if (localPermissionStrAllFbOf) {
                    permissionStr = [NSMutableString stringWithString:localPermissionStrAllFbOf];
                } else if (localPermissionStrSelectedFb) {
                    permissionStr = [NSMutableString stringWithString:localPermissionStrSelectedFb];
                } else {
                    NSAssert(false, @"There should have been atleast some one with permission if we are here");
                }
            } else {
                permissionStr = [NSMutableString stringWithFormat:@"No one"];
            }
            return [permissionStr copy];
            break;
            
        default:
            return @"No one";
            break;
    }
}

+ (NSString *)shortFormattedPermissionObject:(BNPermissionsObject <BNPermissionsObject>*)obj level:(BNPermissionObjectInvitationLevel)level
{
    // Logic of shortFormatting: If there is 1 or 2 names, list them, otherwise list the two names and then say "and n others"
    
    // If there is public permission, then just show that
    NSString *localPermissionsStrPublic = nil;
    NSString *localPermissionStrAllFbOf = nil;
    NSString *localPermissionStrSelectedFb = nil;
    NSMutableString *permissionStr = nil;
    
    switch (level) {
        case BNPermissionObjectInvitationLevelPublic:
            return [self formattedPermissionObjectForPublic:obj];
            break;
            
        case BNPermissionObjectInvitationLevelFacebookFriendsOf:
            return [self shortFormattedPermissionObjectForAllFBFriendsOf:obj];
            break;
            
        case BNPermissionObjectInvitationLevelSelectedFacebookFriends:
            return [self shortFormattedPermissionObjectForFBFriends:obj];
            break;
            
        case BNPermissionObjectInvitationLevelAll:
            localPermissionsStrPublic = [self formattedPermissionObjectForPublic:obj];
            
            if (localPermissionsStrPublic) {
                return localPermissionsStrPublic;
            }
            
            localPermissionStrAllFbOf = [self shortFormattedPermissionObjectForAllFBFriendsOf:obj];
            localPermissionStrSelectedFb = [self shortFormattedPermissionObjectForFBFriends:obj];
            if (localPermissionStrAllFbOf || localPermissionStrSelectedFb) {
                if (localPermissionStrSelectedFb && localPermissionStrAllFbOf) {
                    permissionStr = [NSMutableString stringWithFormat:@"%@ including %@", localPermissionStrAllFbOf, localPermissionStrSelectedFb];
                } else if (localPermissionStrAllFbOf) {
                    permissionStr = [NSMutableString stringWithString:localPermissionStrAllFbOf];
                } else if (localPermissionStrSelectedFb) {
                    permissionStr = [NSMutableString stringWithString:localPermissionStrSelectedFb];
                } else {
                    NSAssert(false, @"There should have been atleast some one with permission if we are here");
                }
            } else {
                permissionStr = [NSMutableString stringWithFormat:@"No one"];
            }
            return [permissionStr copy];
            break;
            
        default:
            return @"No one";
            break;
    }
}

@end

@implementation BNPermissionsObject (InternalMethods)

+ (NSString *)formattedPermissionObjectForPublic:(BNPermissionsObject <BNPermissionsObject>*)obj
{
    if ([obj.inviteeList.isPublic boolValue]) {
        return @"Any one";
    } else {
        return nil;
    }
}

+ (NSString *)longFormattedPermissionObjectForAllFBFriendsOf:(BNPermissionsObject <BNPermissionsObject>*)obj
                                         middleSeperator:(NSString *)middleSeperator lastItemSeperator:(NSString *)lastItemSeperator
{
    NSUInteger lenghtOfFBInviteeList;
    if ((lenghtOfFBInviteeList = obj.inviteeList.allFacebookFriendsOf.count) > 0) {
        NSMutableString *localPermissionStrAllFbOf = nil;
        localPermissionStrAllFbOf = [NSMutableString stringWithFormat:@"Facebook friends of "];
        [obj.inviteeList.allFacebookFriendsOf enumerateObjectsUsingBlock:^(NSDictionary *invitee, NSUInteger idx, BOOL *stop) {
            [localPermissionStrAllFbOf appendString:[invitee objectForKey:@"name"]];
            if (lenghtOfFBInviteeList > 1) {
                if (idx + 1 == lenghtOfFBInviteeList - 1) {
                    [localPermissionStrAllFbOf appendString:lastItemSeperator];
                } else if (idx < lenghtOfFBInviteeList - 1) {
                    [localPermissionStrAllFbOf appendString:middleSeperator];
                }
            }
        }];
        return [localPermissionStrAllFbOf copy];
    } else {
        return nil;
    }
}

+ (NSString *)longFormattedPermissionObjectForFBFriends:(BNPermissionsObject <BNPermissionsObject>*)obj
                                    middleSeperator:(NSString *)middleSeperator lastItemSeperator:(NSString *)lastItemSeperator
{
    NSUInteger lenghtOfFBInviteeList;
    if ((lenghtOfFBInviteeList = obj.inviteeList.facebookFriends.count) > 0) {
        NSMutableString *localPermissionStrSelectedFb = nil;
        localPermissionStrSelectedFb = [NSMutableString string];
        [obj.inviteeList.facebookFriends enumerateObjectsUsingBlock:^(NSDictionary *invitee, NSUInteger idx, BOOL *stop) {
            [localPermissionStrSelectedFb appendString:[invitee objectForKey:@"name"]];
            if (lenghtOfFBInviteeList > 1) {
                if (idx + 1 == lenghtOfFBInviteeList - 1) {
                    [localPermissionStrSelectedFb appendString:lastItemSeperator];
                } else if (idx < lenghtOfFBInviteeList - 1) {
                    [localPermissionStrSelectedFb appendString:middleSeperator];
                }
            }
        }];
        return [localPermissionStrSelectedFb copy];
    } else {
        return nil;
    }
}


+ (NSString *)shortFormattedPermissionObjectForAllFBFriendsOf:(BNPermissionsObject <BNPermissionsObject>*)obj
{
    NSUInteger lenghtOfFBInviteeList;
    if ((lenghtOfFBInviteeList = obj.inviteeList.allFacebookFriendsOf.count) > 0) {
        NSMutableString *localPermissionStrAllFbOf = nil;
        localPermissionStrAllFbOf = [NSMutableString stringWithFormat:@"Facebook friends of "];
        [obj.inviteeList.allFacebookFriendsOf enumerateObjectsUsingBlock:^(NSDictionary *invitee, NSUInteger idx, BOOL *stop) {
            [localPermissionStrAllFbOf appendString:[invitee objectForKey:@"name"]];
            if ((lenghtOfFBInviteeList == 2) && (idx == 0)) {
                [localPermissionStrAllFbOf appendString:@" and "];
            } else if ((lenghtOfFBInviteeList > 2) && (idx == 0)) {
                [localPermissionStrAllFbOf appendString:@", "];
            } else if ((lenghtOfFBInviteeList > 2) && (idx == 1)) {
                [localPermissionStrAllFbOf appendString:[NSString stringWithFormat:@" and %d more", lenghtOfFBInviteeList-idx-1]];
                *stop = YES;
            } else {
                // The length was one, so nothing to do
            }
        }];
        return [localPermissionStrAllFbOf copy];
    } else {
        return nil;
    }
}

+ (NSString *)shortFormattedPermissionObjectForFBFriends:(BNPermissionsObject <BNPermissionsObject>*)obj
{
    NSUInteger lenghtOfFBInviteeList;
    if ((lenghtOfFBInviteeList = obj.inviteeList.facebookFriends.count) > 0) {
        NSMutableString *localPermissionStrSelectedFb = nil;
        localPermissionStrSelectedFb = [NSMutableString string];
        [obj.inviteeList.facebookFriends enumerateObjectsUsingBlock:^(NSDictionary *invitee, NSUInteger idx, BOOL *stop) {
            [localPermissionStrSelectedFb appendString:[invitee objectForKey:@"name"]];
            if ((lenghtOfFBInviteeList == 2) && (idx == 0)) {
                [localPermissionStrSelectedFb appendString:@" and "];
            } else if ((lenghtOfFBInviteeList > 2) && (idx == 0)) {
                [localPermissionStrSelectedFb appendString:@", "];
            } else if ((lenghtOfFBInviteeList > 2) && (idx == 1)) {
                [localPermissionStrSelectedFb appendString:[NSString stringWithFormat:@" and %d more", lenghtOfFBInviteeList-idx-1]];
                *stop = YES;
            } else {
                // The length was one, so nothing to do
            }
        }];
        return [localPermissionStrSelectedFb copy];
    } else {
        return nil;
    }
}


@end

@implementation BNPermissionsInviteeListObject
@synthesize facebookFriends;
@synthesize allFacebookFriendsOf;
@synthesize isPublic;

+ (BNPermissionsInviteeListObject <BNPermissionsInviteeListObject> *)permissionsInviteeListObject
{
    BNPermissionsInviteeListObject<BNPermissionsInviteeListObject> *obj = (BNPermissionsInviteeListObject<BNPermissionsInviteeListObject> *)[BNDuckTypedObject duckTypedObject];
    obj.facebookFriends = [NSMutableArray array];
    obj.allFacebookFriendsOf = [NSMutableArray array];
    obj.isPublic = [NSNumber numberWithBool:NO];
    return obj;
}

@end
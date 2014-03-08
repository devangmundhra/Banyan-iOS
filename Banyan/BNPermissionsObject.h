//
//  BNPermissionsObject.h
//  Banyan
//
//  Created by Devang Mundhra on 10/18/13.
//
//

#import <Foundation/Foundation.h>
#import "BNDuckTypedObject.h"


@protocol BNPermissionsInviteeListObject <BNDuckTypedObject>
@property (assign, nonatomic) NSNumber *isPublic;
@property (strong, nonatomic) NSMutableArray *facebookFriends;
@property (strong, nonatomic) NSMutableArray *allFacebookFriendsOf;
@end
@interface BNPermissionsInviteeListObject : BNDuckTypedObject <BNPermissionsInviteeListObject>
+ (BNPermissionsInviteeListObject <BNPermissionsInviteeListObject> *)permissionsInviteeListObject;
@end

@protocol BNPermissionsObject <BNDuckTypedObject>
@property (strong, nonatomic) NSNumber *permissionsVersion;
@property (strong, nonatomic) BNPermissionsInviteeListObject<BNPermissionsInviteeListObject> *inviteeList;
@end

typedef enum {
    BNPermissionObjectInvitationLevelAll,
    BNPermissionObjectInvitationLevelPublic,
    BNPermissionObjectInvitationLevelFacebookFriendsOf,
    BNPermissionObjectInvitationLevelSelectedFacebookFriends,
} BNPermissionObjectInvitationLevel;

@interface BNPermissionsObject : BNDuckTypedObject <BNPermissionsObject>

+ (BNPermissionsObject <BNPermissionsObject> *)permissionsObject;
+ (NSString *)longFormattedPermissionObject:(BNPermissionsObject <BNPermissionsObject>*)obj level:(BNPermissionObjectInvitationLevel)level list:(BOOL)list;
+ (NSString *)shortFormattedPermissionObject:(BNPermissionsObject <BNPermissionsObject>*)obj level:(BNPermissionObjectInvitationLevel)level;
- (NSString *)typeOfInvitee;
- (NSNumber *)countOfInvitee;
@end

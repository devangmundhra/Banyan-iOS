//
//  BNPermissionsObject.h
//  Banyan
//
//  Created by Devang Mundhra on 10/18/13.
//
//

#import <Foundation/Foundation.h>

@interface BNPermissionsObject : NSObject <NSCopying>

+ (BNPermissionsObject *)permissionObject;
+ (BNPermissionsObject *)permissionObjectWithDictionary:(NSDictionary *)dictionary;
- (NSString *)stringifyPermissionObject;
- (NSDictionary *) permissionsDictionary;

@property (nonatomic, retain) NSString *scope;
@property (nonatomic, retain) NSMutableDictionary *inviteeList;
@property (nonatomic, retain) NSMutableArray *facebookInvitedList;

@end

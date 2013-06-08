//
//  User.h
//  Banyan
//
//  Created by Devang Mundhra on 6/6/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RemoteObject;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * facebookId;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id profilePic;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) RemoteObject *remoteObject;

+ (User *)userForPfUser:(PFUser *)pfUser;
+ (User *)currentUser;
+ (RKEntityMapping *) UserMappingForRK;

@end

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
@property (nonatomic, retain) NSNumber * userId;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) RemoteObject *remoteObject;
@property (nonatomic, retain) NSString *resourceUri;

+ (User *)currentUser;
+ (RKEntityMapping *) UserMappingForRKGET;

@end

@interface BNSharedUser : NSObject

@property (nonatomic, copy) NSString * email;
@property (nonatomic, strong) NSDate * createdAt;
@property (nonatomic, copy) NSString * facebookId;
@property (nonatomic, copy) NSString * firstName;
@property (nonatomic, copy) NSString * lastName;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong) id profilePic;
@property (nonatomic, strong) NSDate * updatedAt;
@property (nonatomic, strong) NSNumber * userId;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString *resourceUri;

+ (BNSharedUser *)currentUser;

@end
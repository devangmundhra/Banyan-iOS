//
//  User.h
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface User : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSDate * dateCreated;
@property (nonatomic, strong) NSString * emailAddress;
@property (nonatomic, strong) NSString * facebookId;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) id profilePic;
@property (nonatomic, strong) NSString * username;

// Session variables. No need to archive
@property (nonatomic, strong) NSString *sessionToken;

+ (User *)currentUser;
+ (User *)getUserForPfUser:(PFUser *)pfUser;
+ (BOOL)loggedIn;
+ (User *)userWithId:(NSString *)id;
- (BOOL) initialized;

+ (void) archiveCurrentUser;
+ (void) unarchiveCurrentUser;
+ (void) deleteCurrentUserFromDisk;
@end

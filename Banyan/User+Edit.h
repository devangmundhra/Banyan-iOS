//
//  User+Edit.h
//  Banyan
//
//  Created by Devang Mundhra on 7/28/12.
//
//

#import "User.h"
#import "User_Defines.h"
#import "AFParseAPIClient.h"

@interface User (Edit)

+ (void) editUser:(User *)user withAttributes:(NSMutableDictionary *)userParams;
+ (User *)currentUser;
+ (BOOL)loggedIn;

@end

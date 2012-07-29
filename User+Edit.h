//
//  User+Edit.h
//  Banyan
//
//  Created by Devang Mundhra on 7/28/12.
//
//

#import "User.h"
#import <Parse/Parse.h>
#import "User_Defines.h"

@interface User (Edit)

+ (void) editUser:(PFUser *)user withAttributes:(NSMutableDictionary *)userParams;

@end

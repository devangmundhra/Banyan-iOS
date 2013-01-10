//
//  User+Create.h
//  Banyan
//
//  Created by Devang Mundhra on 1/1/13.
//
//

#import "User.h"
#import <Parse/Parse.h>

@interface User (Create)

+ (User *)getUserForPfUser:(PFUser *)pfUser inManagedObjectContex:(NSManagedObjectContext *)context;

@end

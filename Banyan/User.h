//
//  User.h
//  Banyan
//
//  Created by Devang Mundhra on 5/2/13.
//
//

#import <Foundation/Foundation.h>

@interface User : NSObject <NSCoding>

@property (nonatomic, strong) NSString * email;
@property (nonatomic, strong) NSString * facebookId;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) UIImage * profilePic;
@property (nonatomic, strong) NSString * userId;
@property (nonatomic, strong) NSString * username;
@property (nonatomic, strong) NSSet *pieces;
@property (nonatomic, strong) NSSet *stories;

+ (User *)userForPfUser:(PFUser *)pfUser;

@end

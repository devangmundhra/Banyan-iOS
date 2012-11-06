//
//  Activity.h
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import <Foundation/Foundation.h>
#import "AFParseAPIClient.h"

@interface Activity : NSObject <NSCoding>

@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *fromUser;
@property (strong, nonatomic) NSString *toUser;
@property (strong, nonatomic) NSString *sceneId;
@property (strong, nonatomic) NSString *storyId;

+ (Activity *) activityWithType:(NSString *)type
                       fromUser:(NSString *)fromUser
                         toUser:(NSString *)toUser
                        sceneId:(NSString *)sceneId
                        storyId:(NSString *)storyId;
+ (void)createActivity:(NSDictionary *)activityContext;
+ (void)deleteActivity:(NSDictionary *)activityContext;

@end

//
//  Activity+Create.m
//  Banyan
//
//  Created by Devang Mundhra on 12/31/12.
//
//

#import "Activity+Create.h"

@implementation Activity (Create)

+ (void)createActivity:(Activity *)activity withCompletionBlock:(void (^)(bool succeeded, NSError *error))block;
{
    NSAssert1(activity.object, @"No object to create an activity of type", activity.type);
    NSAssert1(![activity.type isEqualToString:kBNActivityTypeFollowUser] && ![activity.type isEqualToString:kBNActivityTypeUnfollowUser], @"Invalid activity of type", activity.type);

    [[RKObjectManager sharedManager] postObject:activity
                                           path:nil
                                     parameters:nil
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                            if (block) block(YES, nil);
                                        }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                            BNLogError(@"Error in create activity %@", activity);
                                            if (block) block(NO, error);
                                        }];
}

@end

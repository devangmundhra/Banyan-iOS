//
//  Activity+Create.m
//  Banyan
//
//  Created by Devang Mundhra on 12/31/12.
//
//

#import "Activity+Create.h"

@implementation Activity (Create)

+ (void)createActivity:(Activity *)activity
{
    if (!(activity.piece || activity.story) &&
        !([activity.type isEqualToString:kBNActivityTypeFollowUser] || [activity.type isEqualToString:kBNActivityTypeUnfollowUser])) {
        return;
    }

    [[RKObjectManager sharedManager] postObject:activity
                                           path:nil
                                     parameters:nil
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                            activity.initialized = YES;
                                        }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                            NSLog(@"Error in create activity");
                                        }];
}

@end

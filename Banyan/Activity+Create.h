//
//  Activity+Create.h
//  Banyan
//
//  Created by Devang Mundhra on 12/31/12.
//
//

#import "Activity.h"

@interface Activity (Create)

+ (void)createActivity:(Activity *)activity withCompletionBlock:(void (^)(bool succeeded, NSError *error))block;

@end

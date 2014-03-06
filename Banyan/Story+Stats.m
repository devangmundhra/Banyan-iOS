//
//  Story+Stats.m
//  Banyan
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "Story+Stats.h"
#import "Story+Edit.h"
#import "User.h"
#import "Activity+Create.h"

@implementation Story (Stats)

- (void) setViewedWithCompletionBlock:(void (^)(bool succeeded, NSError *error))block
{
    if (self.viewedByCurUser)
        return;
    
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser)
        return;

    Activity *activity = [Activity activityWithType:kBNActivityTypeView
                                             object:self.resourceUri];
    
    __weak Story *wself = self;
    [Activity createActivity:activity withCompletionBlock:^(bool succeeded, NSError *error) {
        if (succeeded) {
            wself.viewedByCurUser = YES;
            wself.numberOfViews += 1;
        }
        if (block) block(succeeded, error);
    }];
}

@end


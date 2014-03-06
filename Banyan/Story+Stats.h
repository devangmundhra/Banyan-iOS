//
//  Story+Stats.h
//  Banyan
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "Story.h"

@interface Story (Stats)

- (void) setViewedWithCompletionBlock:(void (^)(bool succeeded, NSError *error))block;

@end

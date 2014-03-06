//
//  Piece+Stats.h
//  Banyan
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "Piece.h"

@interface Piece (Stats)

- (void) setViewedWithCompletionBlock:(void (^)(bool succeeded, NSError *error))block;

- (void) toggleLikedWithCompletionBlock:(void (^)(bool succeeded, NSError *error))block;

@end

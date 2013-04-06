//
//  BanyanDataSource.h
//  Banyan
//
//  Created by Devang Mundhra on 7/18/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Story.h"
#import "Piece.h"
#import "File.h"
#import "BanyanConnection.h"

@interface BanyanDataSource : NSObject

+ (NSMutableArray *)shared;
//+ (void) setSharedDatasource:(NSArray *)array;

@end

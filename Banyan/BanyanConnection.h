//
//  BanyanConnection.h
//  Banyan
//
//  Created by Devang Mundhra on 11/11/12.
//
//

#import <Foundation/Foundation.h>
#import "Story.h"
#import "Piece.h"
#import "BanyanDataSource.h"

@interface BanyanConnection : NSObject

+ (RKPaginator *) storiesPaginator;
+ (void) loadDataSource:(id)sender;
+ (void) uploadFailedObjects;

@end

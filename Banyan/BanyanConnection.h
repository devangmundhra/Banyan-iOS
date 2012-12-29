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

+ (void)loadStoriesFromBanyanWithSuccessBlock:(void (^)(NSMutableArray *stories))successBlock errorBlock:(void (^)(NSError *error))errorBlock;
+ (void) resetPermissionsForStories:(NSMutableArray *)stories;
+ (void) loadPiecesForStory:(Story *)story completionBlock:(void (^)())completionBlock errorBlock:(void (^)(NSError *error))errorBlock;
@end

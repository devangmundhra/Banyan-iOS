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
+ (void)loadStoryWithId:(NSString *)storyId
             withParams:(NSDictionary *)params
        completionBlock:(void (^)(Story *story))completionBlock
             errorBlock:(void (^)(NSError *error))errorBlock;
+ (void)loadPieceWithId:(NSString *)pieceId
             withParams:(NSDictionary *)params
        completionBlock:(void (^)(Piece *piece))completionBlock
             errorBlock:(void (^)(NSError *error))errorBlock;
+ (void)loadUserWithId:(NSString *)userId
            withParams:(NSDictionary *)params
       completionBlock:(void (^)(User *user))completionBlock
            errorBlock:(void (^)(NSError *error))errorBlock;

@end

//
//  BanyanConnection.h
//  Banyan
//
//  Created by Devang Mundhra on 11/11/12.
//
//

#import <Foundation/Foundation.h>
#import "Story.h"
#import "Scene.h"
#import "BanyanDataSource.h"

@interface BanyanConnection : NSObject

+ (void)loadStoriesFromBanyanWithBlock:(void (^)(NSMutableArray *stories))successBlock;
+ (void) resetPermissionsForStories:(NSMutableArray *)stories;

@end

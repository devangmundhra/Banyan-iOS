//
//  Piece+Stats.m
//  Banyan
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import "Piece+Stats.h"
#import "Piece+Edit.h"
#import "Activity.h"
#import "Story.h"
#import "User.h"

@implementation Piece (Stats)

- (void) setViewedWithCompletionBlock:(void (^)(bool succeeded, NSError *error))block
{
    if (self.viewedByCurUser)
        return;
    
    if (!self) {
        BNLogError(@"Error: No piece available!!");
        return;
    }
    
    if (self.viewedByCurUser || self.remoteStatus != RemoteObjectStatusSync)
        return;
    
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser)
        return;
    
    Activity *activity = [Activity activityWithType:kBNActivityTypeView object:self.resourceUri];
    
    __weak Piece *wself = self;
    [Activity createActivity:activity withCompletionBlock:^(bool succeeded, NSString *resourceUri, NSError *error) {
        if (succeeded && wself) {
            wself.viewedByCurUser = YES;
            wself.numberOfViews += 1;
            wself.story.numNewPiecesToView = [Piece numPiecesForStory:wself.story withAttribute:@"viewedByCurUser" asValue:[NSNumber numberWithBool:FALSE]];
        }
        if (block) block(succeeded, error);
    }];

    return;
}

- (void) likeWithCompletionBlock:(void (^)(bool succeeded, NSError *error))block
{
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser)
        return;
    
    __weak Piece *wself = self;
    Activity *activity = [Activity activityWithType:kBNActivityTypeLike object:self.resourceUri];
    [Activity createActivity:activity withCompletionBlock:^(bool succeeded, NSString *resourceUri, NSError *error) {
        if (succeeded && wself) {
            wself.likeActivityResourceUri = resourceUri;
            wself.numberOfLikes += 1;
        }
        if (block) block(succeeded, error);
    }];
}

- (void) unlikeWithCompletionBlock:(void (^)(bool succeeded, NSError *error))block
{
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser)
        return;
    
    __weak Piece *wself = self;
    [Activity deleteActivityAtResourceUri:self.likeActivityResourceUri withCompletionBlock:^(bool succeeded, NSError *error) {
        if (succeeded && wself) {
            wself.likeActivityResourceUri = nil;
            wself.numberOfLikes -= 1;
        }
        if (block) block(succeeded, error);
    }];
}

@end

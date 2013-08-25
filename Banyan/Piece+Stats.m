//
//  Piece+Stats.m
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece+Stats.h"
#import "Piece+Edit.h"
#import "AFParseAPIClient.h"
#import "Activity+Create.h"
#import "Story.h"
#import "User.h"

@implementation Piece (Stats)


+ (void) viewedPiece:(Piece *)piece
{
    if (piece.viewedByCurUser)
        return;
    
    if (!piece) {
        NSLog(@"%s --ERROR-- No piece available!!", __PRETTY_FUNCTION__);
        return;
    }
    
    if (piece.viewedByCurUser || piece.remoteStatus != RemoteObjectStatusSync)
        return;
    
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser)
        return;
    
    Activity *activity = [Activity activityWithType:kBNActivityTypeView
                                           fromUser:currentUser.resourceUri
                                             toUser:currentUser.resourceUri
                                            pieceId:piece.resourceUri
                                            storyId:piece.story.resourceUri];
    [Activity createActivity:activity];
    
    piece.viewedByCurUser = YES;
    piece.numberOfViews += 1;
    return;
}

+ (void) toggleLikedPiece:(Piece *)piece
{
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser)
        return;
    
    Activity *activity = nil;
    if (piece.likedByCurUser) {
        // unlike piece
        activity = [Activity activityWithType:kBNActivityTypeUnlike
                                     fromUser:currentUser.resourceUri
                                       toUser:currentUser.resourceUri
                                      pieceId:piece.resourceUri
                                      storyId:piece.story.resourceUri];
        
        piece.likedByCurUser = NO;
        piece.numberOfLikes -= 1;
    }
    else {
        // like piece
        activity = [Activity activityWithType:kBNActivityTypeLike
                                     fromUser:currentUser.resourceUri
                                       toUser:currentUser.resourceUri
                                      pieceId:piece.resourceUri
                                      storyId:piece.story.resourceUri];
        
        piece.likedByCurUser = YES;
        piece.numberOfLikes += 1;
    }
    [Activity createActivity:activity];
}

+ (void) toggleFavouritedPiece:(Piece *)piece
{
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser)
        return;
    Activity *activity = nil;
    if (piece.favoriteByCurUser) {
        // unfavourite piece
        activity = [Activity activityWithType:kBNActivityTypeUnfavourite
                                     fromUser:currentUser.resourceUri
                                       toUser:currentUser.resourceUri
                                      pieceId:piece.resourceUri
                                      storyId:piece.story.resourceUri];
        piece.favoriteByCurUser = NO;
    }
    else {
        // favourite piece
        activity = [Activity activityWithType:kBNActivityTypeFavourite
                                    fromUser:currentUser.resourceUri
                                      toUser:currentUser.resourceUri
                                     pieceId:piece.resourceUri
                                     storyId:piece.story.resourceUri];
        piece.favoriteByCurUser = YES;
    }
    [Activity createActivity:activity];
}

@end

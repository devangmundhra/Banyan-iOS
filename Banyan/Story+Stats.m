//
//  Story+Stats.m
//  Storied
//
//  Created by Devang Mundhra on 4/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Story+Stats.h"
#import "Story+Edit.h"
#import "User.h"
#import "Activity+Create.h"

@implementation Story (Stats)


+ (void) viewedStory:(Story *)story
{
    if (story.viewedByCurUser)
        return;
    
    if (!NUMBER_EXISTS(story.bnObjectId)) {
        NSLog(@"%s Remember to correct this later. Proper counting for views", __PRETTY_FUNCTION__);
        return;
    }
    
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser)
        return;

    Activity *activity = [Activity activityWithType:kBNActivityTypeView
                                           fromUser:currentUser.resourceUri
                                             toUser:currentUser.resourceUri
                                            piece:nil
                                            story:story.resourceUri];
    [Activity createActivity:activity];
    
    story.viewedByCurUser = YES;
    story.numberOfViews += 1;
}

+ (void) toggleLikedStory:(Story *)story
{
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser)
        return;
        
    Activity *activity = nil;
    if (story.likedByCurUser) {
        // unlike story
        story.likedByCurUser = NO;
        activity = [Activity activityWithType:kBNActivityTypeUnlike
                                     fromUser:currentUser.resourceUri
                                       toUser:currentUser.resourceUri
                                      piece:nil
                                      story:story.resourceUri];
        story.numberOfLikes -= 1;
    }
    else {
        // like story
        story.likedByCurUser = YES;
        activity = [Activity activityWithType:kBNActivityTypeLike
                                     fromUser:currentUser.resourceUri
                                       toUser:currentUser.resourceUri
                                      piece:nil
                                      story:story.resourceUri];

        story.numberOfLikes += 1;
    }
    [Activity createActivity:activity];
}

+ (void) toggleFavouritedStory:(Story *)story
{
    BNSharedUser *currentUser = [BNSharedUser currentUser];
    if (!currentUser)
        return;
    
    Activity *activity = nil;
    if (story.favoriteByCurUser) {
        // unfavourite story
        activity = [Activity activityWithType:kBNActivityTypeUnfavourite
                                     fromUser:currentUser.resourceUri
                                       toUser:currentUser.resourceUri
                                      piece:nil
                                      story:story.resourceUri];
        story.favoriteByCurUser = NO;
    }
    else {
        // favourite story
        activity = [Activity activityWithType:kBNActivityTypeFavourite
                                     fromUser:currentUser.resourceUri
                                       toUser:currentUser.resourceUri
                                      piece:nil
                                      story:story.resourceUri];
        story.favoriteByCurUser = YES;
    }
    [Activity createActivity:activity];
}

@end


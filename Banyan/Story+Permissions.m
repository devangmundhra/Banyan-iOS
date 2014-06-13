//
//  Story+Permissions.m
//  Banyan
//
//  Created by Devang Mundhra on 12/31/12.
//
//

#import "Story+Permissions.h"
#import "AFBanyanAPIClient.h"
#import "User.h"
#import "Piece.h"

NSString *const kDictionaryInSortedArrayOfContributorsNameKey = @"name";
NSString *const kDictionaryInSortedArrayOfContributorsCountKey = @"count";

@implementation Story (Permissions)

// Array of all contributors including author
- (NSArray *) arrayOfPieceContributors
{
    NSMutableArray *contributorArray = [NSMutableArray array];
    // Add author of story first
    if (self.author && !self.author.hasBeenDeleted && self.author.name) {
        [contributorArray addObject:[self.author.name copy]];
    } else {
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"Error" action:@"story.author not found" label:nil value:[NSNumber numberWithBool:self.author.hasBeenDeleted]];
        [contributorArray addObject:@""];
    }
    
    // Add other pieces first
    for (Piece *piece in self.pieces) {
        if (piece.author && !piece.author.hasBeenDeleted && piece.author.name) {
            // it is possible that we don't have an author because we don't store the piece when creating a backup
            // There are some crahes happening because the piece.author cannot fulfil fault.
            // I suspect this can happen when a piece is being filled while the story is refreshed (say when the app is opened
            // from a push notification. In that case it is better to check if the piece.author is not already deleted
            // For example, consider this scenario-
            // 1. App is opened from a notification
            // 2. [AppDelegate makeKeyAndDisplay] is loading the view, concurrently the story is being updated by RestKit
            // 3. Since every new mapping of a user is a new author for the piece or story, RestKit makes a new mapping
            //    for this user and deletes the previous one, while this method is still using the previous user
            [contributorArray addObject:[piece.author.name copy]];
        } else {
            [BNMisc sendGoogleAnalyticsEventWithCategory:@"Error" action:@"piece.author not found" label:nil value:[NSNumber numberWithBool:piece.author.hasBeenDeleted]];
        }
    }
    
    return [NSOrderedSet orderedSetWithArray:contributorArray].array;
}

// String of contributors separated by comma including author
- (NSString *)shortStringOfContributors
{
    NSUInteger lengthOfContributors;
    NSArray *pieceContributorsArray = [self arrayOfPieceContributors];
    if ((lengthOfContributors = pieceContributorsArray.count) > 0) {
        NSMutableString *contributorStr = nil;
        contributorStr = [NSMutableString string];
        [pieceContributorsArray enumerateObjectsUsingBlock:^(NSString *contributorName, NSUInteger idx, BOOL *stop) {
            [contributorStr appendString:contributorName];
            if ((lengthOfContributors == 2) && (idx == 0)) {
                [contributorStr appendString:@" and "];
            } else if ((lengthOfContributors > 2) && (idx == 0)) {
                [contributorStr appendString:[NSString stringWithFormat:@" and %d more", lengthOfContributors-idx-1]];
                *stop = YES;
            } else {
                // The length was one, so nothing to do
            }
        }];
        return [contributorStr copy];
    } else {
        return nil;
    }
}

// Array of contributors sorted descending
- (NSArray *) sortedArrayOfPieceContributorsWithCount
{
    NSCountedSet *countedSet = [[NSCountedSet alloc] initWithCapacity:1];
    for (Piece *piece in self.pieces) {
        [countedSet addObject:[piece.author.name copy]];
    }
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:1];
    NSEnumerator *enumerator = [countedSet objectEnumerator];
    NSString *contributor = nil;
    
    while (contributor = [enumerator nextObject]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:contributor forKey:kDictionaryInSortedArrayOfContributorsNameKey];
        [dict setValue:[NSNumber numberWithUnsignedInteger:[countedSet countForObject:contributor]] forKey:kDictionaryInSortedArrayOfContributorsCountKey];
        [array addObject:dict];
    }
    
    NSSortDescriptor * countSortDescriptor = [[NSSortDescriptor alloc] initWithKey:kDictionaryInSortedArrayOfContributorsCountKey
                                                 ascending:NO];
    NSSortDescriptor * nameSortDescriptor = [[NSSortDescriptor alloc] initWithKey:kDictionaryInSortedArrayOfContributorsNameKey
                                                                         ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:countSortDescriptor, nameSortDescriptor, nil];
    NSArray *sortedArray = [array sortedArrayUsingDescriptors:sortDescriptors];
    
    return sortedArray;
}

@end

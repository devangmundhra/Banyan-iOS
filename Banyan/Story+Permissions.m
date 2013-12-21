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
    [contributorArray addObject:REPLACE_NIL_WITH_EMPTY_STRING(self.author.name)];
    
    // Add other pieces first
    for (Piece *piece in self.pieces) {
        if (piece.author) // No author is possible for backup Piece when editing a piece
            [contributorArray addObject:piece.author.name];
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
                [contributorStr appendString:@", "];
            } else if ((lengthOfContributors > 2) && (idx == 1)) {
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
        [countedSet addObject:piece.author.name];
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

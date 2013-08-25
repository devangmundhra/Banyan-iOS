//
//  Story.h
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RemoteObject.h"

@class Piece;

@interface Story : RemoteObject

@property (nonatomic) BOOL canContribute;
@property (nonatomic) BOOL canView;
@property (nonatomic, retain) id contributors;
@property (nonatomic) BOOL isInvited;
@property (nonatomic) int16_t length;
@property (nonatomic, retain) id readAccess;
@property (nonatomic) int16_t currentPieceNum;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) id writeAccess;
@property (nonatomic, retain) NSOrderedSet *pieces;
@property (nonatomic, retain) NSNumber * uploadStatusNumber;
@property (nonatomic, retain) NSNumber * primitiveUploadStatusNumber;
@property (nonatomic, retain) NSString * sectionIdentifier;
@property (nonatomic, retain) NSString * primitiveSectionIdentifier;
@property (nonatomic) BOOL newPiecesToView;


+ (NSArray *)storiesFailedToBeUploaded;
+ (NSArray *)syncedStories;
+ (NSArray *)unsavedStories;
- (NSNumber *)calculateUploadStatusNumber;
- (void) saveStoryMOIdToUserDefaults;
+ (Story *)getCurrentOngoingStoryToContribute;
+ (NSArray *)getStoriesUserCanContributeTo;
+ (RKEntityMapping *)storyMappingForRK;
@end

@interface Story (CoreDataGeneratedAccessors)

- (void)insertObject:(Piece *)value inPiecesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPiecesAtIndex:(NSUInteger)idx;
- (void)insertPieces:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePiecesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPiecesAtIndex:(NSUInteger)idx withObject:(Piece *)value;
- (void)replacePiecesAtIndexes:(NSIndexSet *)indexes withPieces:(NSArray *)values;
- (void)addPiecesObject:(Piece *)value;
- (void)removePiecesObject:(Piece *)value;
- (void)addPieces:(NSOrderedSet *)values;
- (void)removePieces:(NSOrderedSet *)values;
@end

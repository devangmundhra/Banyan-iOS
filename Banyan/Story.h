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

@property (nonatomic, retain) NSNumber * canContribute;
@property (nonatomic, retain) NSNumber * canView;
@property (nonatomic, retain) id contributors;
@property (nonatomic, retain) NSNumber * isInvited;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSNumber * numberOfContributors;
@property (nonatomic, retain) id readAccess;
@property (nonatomic, retain) NSNumber * storyBeingRead;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) id writeAccess;
@property (nonatomic, retain) NSOrderedSet *pieces;

+ (NSArray *)syncedStories;
+ (NSArray *)unsavedStories;

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

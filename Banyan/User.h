//
//  User.h
//  Banyan
//
//  Created by Devang Mundhra on 1/3/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Piece, Story;

@interface User : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * emailAddress;
@property (nonatomic, retain) NSString * facebookId;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id profilePic;
@property (nonatomic, retain) NSString * sessionToken;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *pieces;
@property (nonatomic, retain) NSSet *stories;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addPiecesObject:(Piece *)value;
- (void)removePiecesObject:(Piece *)value;
- (void)addPieces:(NSSet *)values;
- (void)removePieces:(NSSet *)values;

- (void)addStoriesObject:(Story *)value;
- (void)removeStoriesObject:(Story *)value;
- (void)addStories:(NSSet *)values;
- (void)removeStories:(NSSet *)values;

@end

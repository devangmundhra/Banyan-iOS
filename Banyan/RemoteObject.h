//
//  RemoteObject.h
//  Banyan
//
//  Created by Devang Mundhra on 5/15/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GooglePlacesObject.h"

typedef enum {
    RemoteObjectStatusLocal,       // Only local version
    RemoteObjectStatusPushing,    // Uploading post
    RemoteObjectStatusFailed,      // Upload failed
    RemoteObjectStatusSync,       // Post uploaded
} RemoteObjectStatus;

@class Comment, Media, User;

@interface RemoteObject : NSManagedObject

@property (nonatomic, retain) User * author;
@property (nonatomic, retain) NSNumber * bnObjectId;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic) BOOL isLocationEnabled;
@property (nonatomic, retain) NSDate * lastSynced;
@property (nonatomic, retain) BNDuckTypedObject<GooglePlacesObject> * location;
@property (nonatomic, retain) NSNumber * remoteStatusNumber;
@property (nonatomic, retain) NSNumber * primitiveRemoteStatusNumber;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic) RemoteObjectStatus remoteStatus;
@property (nonatomic, retain) NSString * permaLink;
@property (nonatomic, retain) NSNumber * timeStamp;
@property (nonatomic, strong) NSString *resourceUri;

// Stats
@property (nonatomic) BOOL viewedByCurUser;
@property (nonatomic) BOOL likedByCurUser;
@property (nonatomic) BOOL favoriteByCurUser;
@property (nonatomic) int16_t numberOfLikes;
@property (nonatomic) int16_t numberOfViews;
// Relationships
@property (nonatomic, retain) NSSet * comments;
@property (nonatomic, retain) NSOrderedSet * media;

// Revision management
- (void)cloneFrom:(RemoteObject *)source;

#pragma mark Data management
- (void)save;
- (void) remove;
+ (void)validateAllObjects;
+ (NSUInteger) numRemoteObjectsWithPendingChanges;

# pragma mark sharing
- (void) shareOnFacebook;
- (void) performFacebookPublishAction:(void (^)(void)) action;
- (void)showAlert:(NSString *)message
           result:(id)result
            error:(NSError *)error;

// Misc methods
- (NSString *)getIdentifierForMediaFileName;
@end


@interface RemoteObject (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)insertObject:(Media *)value inMediaAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMediaAtIndex:(NSUInteger)idx;
- (void)insertMedia:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMediaAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMediaAtIndex:(NSUInteger)idx withObject:(Media *)value;
- (void)replaceMediaAtIndexes:(NSIndexSet *)indexes withMedia:(NSArray *)values;
- (void)addMediaObject:(Media *)value;
- (void)removeMediaObject:(Media *)value;
- (void)addMedia:(NSOrderedSet *)values;
- (void)removeMedia:(NSOrderedSet *)values;
- (void)exchangeObjectInMediaAtIndex:(NSUInteger)idx withObjectInMediaAtIndex:(NSUInteger)idx;
@end

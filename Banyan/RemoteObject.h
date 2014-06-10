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
@class BNS3TransferManager;

@interface RemoteObject : NSManagedObject

@property (nonatomic, retain) User * author;
@property (nonatomic, retain) NSNumber * bnObjectId;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * lastSynced;
@property (nonatomic, retain) GooglePlacesObject<GooglePlacesObject> * location;
@property (nonatomic, retain) NSNumber * remoteStatusNumber;
@property (nonatomic, retain) NSNumber * primitiveRemoteStatusNumber;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic) RemoteObjectStatus remoteStatus;
@property (nonatomic, retain) NSString * permaLink;
@property (nonatomic, retain) NSNumber * timeStamp;
@property (nonatomic, retain) NSString *resourceUri;
@property (nonatomic) float uploadProgress;
// Stats
@property (nonatomic) BOOL viewedByCurUser;
@property (nonatomic, copy) NSString *likeActivityResourceUri;
@property (nonatomic) int16_t numberOfLikes;
@property (nonatomic) int16_t numberOfViews;
// Relationships
@property (nonatomic, retain) NSSet * comments;
@property (nonatomic, retain) NSOrderedSet * media;

@property (nonatomic, strong) BNS3TransferManager *transferManager;
@property (atomic, strong) RKObjectRequestOperation *ongoingOperation;

- (void) updateUploadProgress;

// Revision management
- (RemoteObject *) cloneIntoNSManagedObjectContext:(NSManagedObjectContext *)newContext;
- (void)cloneFrom:(RemoteObject *)source;

#pragma mark Data management
- (void)save;
- (void) remove;
+ (void)validateAllObjects;
+ (NSUInteger) numRemoteObjectsWithPendingChanges;

// Misc methods
- (NSString *)getIdentifierForMediaFileName;
- (void) cancelAnyOngoingOperation;
- (void) uploadFailedRemoteObject;
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

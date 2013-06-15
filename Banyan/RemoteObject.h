//
//  RemoteObject.h
//  Banyan
//
//  Created by Devang Mundhra on 5/15/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Statistics.h"
#import <FacebookSDK/FacebookSDK.h>

typedef enum {
    RemoteObjectStatusPushing,    // Uploading post
    RemoteObjectStatusFailed,      // Upload failed
    RemoteObjectStatusLocal,       // Only local version
    RemoteObjectStatusSync,       // Post uploaded
} RemoteObjectStatus;

@class Comment, Media, Statistics, User;

@interface RemoteObject : NSManagedObject

@property (nonatomic, retain) User * author;
@property (nonatomic, retain) NSString * bnObjectId;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSNumber * isLocationEnabled;
@property (nonatomic, retain) NSDate * lastSynced;
@property (nonatomic, retain) FBGraphObject<FBGraphPlace> * location;
@property (nonatomic, retain) NSNumber * remoteStatusNumber;
@property (nonatomic, retain) Statistics * statistics;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic) RemoteObjectStatus remoteStatus;
@property (nonatomic, retain) NSString * permaLink;

// Relationships
@property (nonatomic, retain) NSSet * comments;
@property (nonatomic, retain) NSSet * media;

// Revision management
- (void)cloneFrom:(RemoteObject *)source;

#pragma mark Data management
- (void)save;
- (void) remove;
+ (void)validateAllObjects;

# pragma mark sharing
- (void)share;

@end

@interface RemoteObject (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addMediaObject:(Media *)value;
- (void)removeMediaObject:(Media *)value;
- (void)addMedia:(NSSet *)values;
- (void)removeMedia:(NSSet *)values;

@end

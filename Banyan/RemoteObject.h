//
//  RemoteObject.h
//  Banyan
//
//  Created by Devang Mundhra on 4/26/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Statistics.h"
#import "User.h"
#import <FacebookSDK/FacebookSDK.h>

typedef enum {
    RemoteObjectStatusPushing,    // Uploading post
    RemoteObjectStatusFailed,      // Upload failed
    RemoteObjectStatusLocal,       // Only local version
    RemoteObjectStatusSync,       // Post uploaded
} RemoteObjectStatus;

@class Statistics, Media;

@interface RemoteObject : NSManagedObject

@property (nonatomic, retain) User * author;
@property (nonatomic, retain) NSString * bnObjectId;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * lastSynced;
@property (nonatomic, retain) NSNumber * remoteStatusNumber;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, strong) Statistics *statistics;
@property (nonatomic, retain) NSNumber * isLocationEnabled;
@property (nonatomic, strong) FBGraphObject<FBGraphPlace> * location;
@property (nonatomic) RemoteObjectStatus remoteStatus;
@property (nonatomic, retain) NSString * permaLink;

// Relationships
@property (nonatomic, strong) NSMutableSet * comments;
@property (nonatomic, retain) Media *media;

// Revision management
- (void)cloneFrom:(RemoteObject *)source;
- (void)save;

#pragma mark Data management
- (void) remove;

# pragma mark sharing
- (void)share;
@end

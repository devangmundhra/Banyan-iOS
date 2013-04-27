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
#import <FacebookSDK/FacebookSDK.h>

typedef enum {
    RemoteObjectStatusPushing,    // Uploading post
    RemoteObjectStatusFailed,      // Upload failed
    RemoteObjectStatusLocal,       // Only local version
    RemoteObjectStatusSync,       // Post uploaded
} RemoteObjectStatus;

@class Statistics, Media;

@interface RemoteObject : NSManagedObject

@property (nonatomic, retain) NSString * authorId;
@property (nonatomic, retain) NSString * bnObjectId;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * lastSynced;
@property (nonatomic, retain) NSNumber * remoteStatusNumber;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) Media *media;
@property (nonatomic, strong) Statistics *statistics;
@property (nonatomic, retain) NSNumber * isLocationEnabled;
@property (nonatomic, strong) id<FBGraphPlace> location;
@property (nonatomic) RemoteObjectStatus remoteStatus;

// Revision management
- (void)cloneFrom:(RemoteObject *)source;
- (void)save;

#pragma mark Data management
- (void) remove;

@end

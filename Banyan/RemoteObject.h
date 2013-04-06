//
//  RemoteObject.h
//  Banyan
//
//  Created by Devang Mundhra on 3/26/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum {
    RemoteObjectStatusPushing,    // Uploading post
    RemoteObjectStatusFailed,      // Upload failed
    RemoteObjectStatusLocal,       // Only local version
    RemoteObjectStatusSync,       // Post uploaded
} RemoteObjectStatus;


@interface RemoteObject : NSManagedObject

@property (nonatomic, retain) NSString * bnObjectId;
@property (nonatomic, retain) NSString * authorId;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * remoteStatusNumber;
@property (nonatomic) RemoteObjectStatus remoteStatus;

// Revision management
- (void)cloneFrom:(RemoteObject *)source;
- (void)save;

#pragma mark Data management
- (void) remove;
@end

//
//  RemoteObject.m
//  Banyan
//
//  Created by Devang Mundhra on 3/26/13.
//
//

#import "RemoteObject.h"


@implementation RemoteObject

@dynamic bnObjectId;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic remoteStatusNumber;
@synthesize authorId;

#pragma mark -
#pragma mark Revision management
- (void)cloneFrom:(RemoteObject *)source {
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        NSLog(@"Copying attribute %@", key);
        [self setValue:[source valueForKey:key] forKey:key];
    }
}

- (RemoteObjectStatus)remoteStatus {
    return (RemoteObjectStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(RemoteObjectStatus)aStatus {
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

- (void)save
{
    NSError *error = nil;
    if (![self.managedObjectContext saveToPersistentStore:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

- (void) remove
{
    if (self.remoteStatus == RemoteObjectStatusPushing || self.remoteStatus == RemoteObjectStatusLocal) {
        // Send notification to cancel this upload
    }
    
    [[self managedObjectContext] deleteObject:self];
    [self save];
}

@end

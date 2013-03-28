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

@end

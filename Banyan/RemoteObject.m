//
//  RemoteObject.m
//  Banyan
//
//  Created by Devang Mundhra on 5/15/13.
//
//

#import "RemoteObject.h"
#import "Comment.h"
#import "Media.h"


@implementation RemoteObject

@dynamic author;
@dynamic bnObjectId;
@dynamic createdAt;
@dynamic isLocationEnabled;
@dynamic lastSynced;
@dynamic location;
@dynamic remoteStatusNumber;
@dynamic statistics;
@dynamic updatedAt;
@dynamic permaLink;
@dynamic comments;
@dynamic media;


#pragma mark -
#pragma mark Revision management
- (void)cloneFrom:(RemoteObject *)source {
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        NSLog(@"Copying attribute %@", key);
        [self setValue:[source valueForKey:key] forKey:key];
    }
    for (NSString *key in [[[source entity] relationshipsByName] allKeys]) {
        if ([key isEqualToString:@"original"] || [key isEqualToString:@"revision"]) {
            NSLog(@"Skipping relationship %@", key);
        } else if ([key isEqualToString:@"comments"]) {
            NSLog(@"Copying relationship %@", key);
            [self setComments:[source comments]];
        } else if ([key isEqualToString:@"media"]) {
            NSLog(@"Copying relationship %@", key);
            [self setMedia:[source media]];
//            self.media = [Media newMediaForObject:self];
//            for (NSString *key in [[[source.media entity] attributesByName] allKeys]) {
//                NSLog(@"Copying media attribute %@", key);
//                [self.media setValue:[source.media valueForKey:key] forKey:key];
//            }
        } else {
            NSLog(@"Copying relationship %@", key);
            [self setValue: [source valueForKey:key] forKey: key];
        }
    }
}

- (RemoteObjectStatus)remoteStatus {
    return (RemoteObjectStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(RemoteObjectStatus)aStatus {
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus {
    switch ([remoteStatus intValue]) {
        case RemoteObjectStatusPushing:
            return NSLocalizedString(@"Uploading", @"");
            break;
        case RemoteObjectStatusFailed:
            return NSLocalizedString(@"Failed", @"");
            break;
        case RemoteObjectStatusSync:
            return NSLocalizedString(@"Posts", @"");
            break;
        default:
            return NSLocalizedString(@"Local", @"");
            break;
    }
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

#pragma mark-
#pragma mark RestKit dynamic mapping
- (BOOL)validateLocation:(id *)ioValue error:(NSError **)outError
{
    *ioValue = [FBGraphObject graphObjectWrappingDictionary:*ioValue];
    return YES;
}

# pragma mark sharing
- (void)share {
}

@end

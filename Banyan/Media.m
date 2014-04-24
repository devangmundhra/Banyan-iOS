//
//  Media.m
//  Banyan
//
//  Created by Devang Mundhra on 5/15/13.
//
//

#import "Media.h"
#import "RemoteObject.h"
#import "Media+Transfer.h"
#import "BNS3TransferManager.h"

@implementation Media

@dynamic createdAt;
@dynamic filename;
@dynamic filesize;
@dynamic height;
@dynamic length;
@dynamic localURL;
@dynamic mediaType;
@dynamic orientation;
@dynamic progress;
@dynamic remoteStatusNumber;
@dynamic remoteURL;
@dynamic thumbnail;
@dynamic thumbnailURL;
@dynamic title;
@dynamic width;
@dynamic remoteObject;
@dynamic thumbnailfilename;

+ (Media *)newMediaForObject:(RemoteObject *)remoteObject
{
    if (![remoteObject managedObjectContext]) {
        [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Problem in trying to add this media to the %@", [[remoteObject entity].description lowercaseString]]
                                    message:@"Please cancel and try again. Sorry for the inconvenience!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [BNMisc sendGoogleAnalyticsEventWithCategory:@"Error" action:@"No context for new media" label:[remoteObject entity].description value:nil];
        return nil;
    }
    Media *media = [NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:[remoteObject managedObjectContext]];
    
    media.remoteObject = remoteObject;
    media.filename = [BNMisc genRandStringLength:10];
    media.createdAt = [NSDate date];
    media.remoteStatus = MediaRemoteStatusLocal;
//    [media save];
    
    return media;
}

- (void)remove {
    [self cancelUpload];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.localURL error:&error];
    [[self managedObjectContext] deleteObject:self];
    [self save];
}

- (void)save
{
    NSError *error = nil;
    if (![self.managedObjectContext saveToPersistentStore:&error]) {
        BNLogError(@"Unresolved Core Data Save error %@, %@ in saving media", error, [error userInfo]);
        exit(-1);
    }
}

- (void)cloneFrom:(Media *)source
{
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        // Skip filename to avoid getting multiple media object when mapping through restkit identificationAttributes
        if ([key isEqualToString:@"filename"]) {
            BNLogTrace(@"Skipping attribute %@", key);
            continue;
        }
        BNLogTrace(@"Copying attribute %@", key);
        [self setValue:[source valueForKey:key] forKey:key];
    }
    
    for (NSString *key in [[[source entity] relationshipsByName] allKeys]) {
        if ([key isEqualToString:@"remoteObject"]) {
            BNLogTrace(@"Skipping relationship %@", key);
        } else {
            BNLogTrace(@"Copying relationship %@", key);
            [self setValue: [source valueForKey:key] forKey: key];
        }
    }
}

- (void)awakeFromFetch {
    if ((self.remoteStatus == MediaRemoteStatusPushing && self.remoteObject.transferManager.operationQueue.operationCount == 0) || (self.remoteStatus == MediaRemoteStatusProcessing)) {
        self.remoteStatus = MediaRemoteStatusFailed;
    }
}

- (MediaRemoteStatus)remoteStatus {
    return (MediaRemoteStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(MediaRemoteStatus)aStatus {
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

- (float)progress {
    [self willAccessValueForKey:@"progress"];
    NSNumber *result = [self primitiveValueForKey:@"progress"];
    [self didAccessValueForKey:@"progress"];
    return [result floatValue];
}

- (void)setProgress:(float)progress {
    [self willChangeValueForKey:@"progress"];
    [self setPrimitiveValue:[NSNumber numberWithFloat:progress] forKey:@"progress"];
    [self didChangeValueForKey:@"progress"];
}

- (NSString *)mediaTypeName {
    if ([self.mediaType isEqualToString:@"image"]) {
        return NSLocalizedString(@"Image", @"");
    } else if ([self.mediaType isEqualToString:@"video"]) {
        return NSLocalizedString(@"Video", @"");
    } else if ([self.mediaType isEqualToString:@"audio"]) {
        return NSLocalizedString(@"Audio", @"");
    } else if ([self.mediaType isEqualToString:@"gif"]) {
        return NSLocalizedString(@"Gif", @"");
    } else {
        return self.mediaType;
    }
}

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus {
    switch ([remoteStatus intValue]) {
        case MediaRemoteStatusPushing:
            return NSLocalizedString(@"Uploading", @"");
            break;
        case MediaRemoteStatusFailed:
            return NSLocalizedString(@"Failed", @"");
            break;
        case MediaRemoteStatusSync:
            return NSLocalizedString(@"Uploaded", @"");
            break;
        default:
            return NSLocalizedString(@"Pending", @"");
            break;
    }
}

- (NSString *)remoteStatusText {
    return [Media titleForRemoteStatus:self.remoteStatusNumber];
}

+ (void) validateAllMedias
{
    // Any objects which are in the Uploading state should be marked as failed
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Media" inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
    
    // Delete all media with no remoteObject
    // This usually happens because there can be a mismatch between a GET request coming down from a server while another PUT/POST request is happening.
    // Consider the scenario where a piece with media failed to upload, and the app was closed. On the next open, the stories and pieces will be
    // GET from the backend, while a piece is being uploaded. It can well happen that the piece has been uploaded but the media hasn't been uploaded.
    // Now if the upload of the media happens first, there will be a piece with the media. But later when the backend replies with the piece with
    // an empty media, the media gets disconnected from the remoteObject, and the piece has no media.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteObject = nil"];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *array = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:request error:&error];
    for (Media *obj in array)
        [obj remove];
}



+ (RKEntityMapping *)mediaMappingForRKGET
{
    RKEntityMapping *mediaMapping = [RKEntityMapping mappingForEntityForName:kBNMediaClassKey
                                                        inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [mediaMapping addAttributeMappingsFromDictionary:@{@"url": @"remoteURL"}];
    [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType", @"thumbnailURL", @"thumbnailfilename"]];
    mediaMapping.identificationAttributes = @[@"filename", @"remoteURL"];
    return mediaMapping;
}

+ (RKObjectMapping *)mediaRequestMapping
{
    RKObjectMapping *mediaMapping = [RKObjectMapping requestMapping];
    [mediaMapping addAttributeMappingsFromDictionary:@{@"remoteURL": @"url"}];
    [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType", @"thumbnailURL", @"thumbnailfilename"]];
    return mediaMapping;
}

+ (Media *)getMediaOfType:(NSString *)type inMediaSet:(NSOrderedSet *)mediaSet
{
    Media *mediaToReturn = nil;
    for (Media *media in mediaSet) {
        if ([media.mediaType isEqualToString:type]) {
            mediaToReturn = media;
            break;
        }
    }
    return mediaToReturn;
}

+ (NSOrderedSet *)getAllMediaOfType:(NSString *)type inMediaSet:(NSOrderedSet *)mediaSet
{
    NSMutableOrderedSet *mediaToReturn = [NSMutableOrderedSet orderedSet];
    for (Media *media in mediaSet) {
        if ([media.mediaType isEqualToString:type]) {
            [mediaToReturn insertObject:media atIndex:mediaToReturn.count];
        }
    }
    
    return mediaToReturn.count ? mediaToReturn : nil;
}
@end

//
//  Media.h
//  Banyan
//
//  Created by Devang Mundhra on 5/15/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BNMisc.h"
#import "SDWebImage/SDWebImageDownloader.h"

typedef NS_ENUM(NSUInteger, MediaRemoteStatus) {
    MediaRemoteStatusLocal,       // Only local version
    MediaRemoteStatusPushing,    // Uploading post
    MediaRemoteStatusFailed,      // Upload failed
    MediaRemoteStatusSync,       // Post uploaded
    MediaRemoteStatusProcessing, // Intermediate status before uploading
};


@class RemoteObject;

@interface Media : NSManagedObject
#define MEDIA_THUMBNAIL_SIZE CGSizeMake(300, 130)

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * filesize;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSString * localURL;
@property (nonatomic, retain) NSString * mediaType;
@property (weak, nonatomic, readonly) NSString * mediaTypeName;
@property (nonatomic, retain) NSString * orientation;
@property (nonatomic) float progress;
@property (nonatomic, retain) NSNumber * remoteStatusNumber;
@property (nonatomic, retain) NSString * remoteURL;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) UIImage * thumbnail;
@property (nonatomic, retain) NSString *thumbnailfilename;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) RemoteObject *remoteObject;

@property (nonatomic) MediaRemoteStatus remoteStatus;

+ (Media *)newMediaForObject:(RemoteObject *)remoteObject;

- (void)remove;
- (void)save;
- (void)cloneFrom:(Media *)source;

+ (Media *)getMediaOfType:(NSString *)type inMediaSet:(NSOrderedSet *)mediaSet;
+ (NSOrderedSet *)getAllMediaOfType:(NSString *)type inMediaSet:(NSOrderedSet *)mediaSet;
+ (RKEntityMapping *)mediaMappingForRKGET;
+ (RKObjectMapping *)mediaRequestMapping;

+ (void)validateAllMedias;

@end

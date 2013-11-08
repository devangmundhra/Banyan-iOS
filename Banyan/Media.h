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

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSNumber * filesize;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSString * localURL;
@property (nonatomic, retain) NSNumber * mediaID;
@property (nonatomic, retain) NSString * mediaType;
@property (weak, nonatomic, readonly) NSString * mediaTypeName;
@property (nonatomic, retain) NSString * orientation;
@property (nonatomic) float progress;
@property (nonatomic, retain) NSNumber * remoteStatusNumber;
@property (nonatomic, retain) NSString * remoteURL;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) RemoteObject *remoteObject;

@property (nonatomic) MediaRemoteStatus remoteStatus;

- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void) deleteWitSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))errorBlock;

+ (Media *)newMediaForObject:(RemoteObject *)remoteObject;
- (void)cancelUpload;
- (void)remove;
- (void)save;
- (void)cloneFrom:(Media *)source;

- (id<SDWebImageOperation>) getImageForMediaWithSuccess:(void (^)(UIImage *))success failure:(void (^)(NSError *error))failure;
- (id<SDWebImageOperation>) getImageWithContentMode:(UIViewContentMode)contentMode
                          bounds:(CGSize)size
            interpolationQuality:(CGInterpolationQuality)quality
             forMediaWithSuccess:(void (^)(UIImage *))success
                         failure:(void (^)(NSError *error))failure;

+ (Media *)getMediaOfType:(NSString *)type inMediaSet:(NSOrderedSet *)mediaSet;
+ (NSOrderedSet *)getAllMediaOfType:(NSString *)type inMediaSet:(NSOrderedSet *)mediaSet;
+ (RKEntityMapping *)mediaMappingForRK;

+ (void)validateAllMedias;

@end

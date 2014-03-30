//
//  Media+Transfer.h
//  Banyan
//
//  Created by Devang Mundhra on 3/19/14.
//
//

#import "Media.h"

@interface Media (Transfer)

- (void)cancelUpload;
- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void) deleteWitSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))errorBlock;
- (void) getImageForMediaWithSuccess:(void (^)(UIImage *image))success
                            progress:(void (^)(NSUInteger receivedSize, long long expectedSize))progress
                             failure:(void (^)(NSError *error))failure
                    includeThumbnail:(BOOL) includeThumbnail;
- (void) getImageWithContentMode:(UIViewContentMode)contentMode
                          bounds:(CGSize)size
            interpolationQuality:(CGInterpolationQuality)quality
             forMediaWithSuccess:(void (^)(UIImage *image))success
                        progress:(void (^)(NSUInteger receivedSize, long long expectedSize))progress
                         failure:(void (^)(NSError *error))failure
                includeThumbnail:(BOOL) includeThumbnail;

@end
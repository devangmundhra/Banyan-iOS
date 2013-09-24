//
//  BNAWSS3Client.m
//  Banyan
//
//  Created by Devang Mundhra on 8/22/13.
//
//

#import "BNAWSS3Client.h"
#import "BanyanAppDelegate.h"

static NSString *AWSS3BucketName = @"banyancontent";

@implementation BNAWSS3Client

+ (AmazonS3Client *)sharedClient
{
    static AmazonS3Client *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AmazonS3Client alloc] initWithAccessKey:AWS_ACCESS_KEY withSecretKey:AWS_SECRET_KEY];
    });
    
    return _sharedClient;
}

+ (void) uploadData:(NSData *)data withContentType:(NSString *)contentType
        forFileName:(NSString *)filename
inBackgroundWithBlock:(void (^)(bool succeeded, NSString *url, NSString *filename, NSError *error))block
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // Upload image data.  Remember to set the content type.
        S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:filename
                                                                  inBucket:AWSS3BucketName];
        por.contentType = contentType;
        por.data        = data;
        
        // Put the image data into the specified s3 bucket and object.
        S3PutObjectResponse *putObjectResponse = [self.sharedClient putObject:por];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (putObjectResponse.error != nil)
            {
                block(NO, nil, nil, putObjectResponse.error);
            }
            else
            {
                block(YES, [por.url absoluteString], filename, putObjectResponse.error);
            }
        });
    });
}

+ (void) deleteObjectWithFileName:(NSString *)filename inBackgroundWithBlock:(void (^)(bool succeeded, NSError *error))block
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // Delete the object
        S3DeleteObjectResponse *deleteObjectResponse = [self.sharedClient deleteObjectWithKey:filename withBucket:AWSS3BucketName];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (deleteObjectResponse.error != nil)
                block(NO, deleteObjectResponse.error);
            else
                block(YES, nil);
        });
    });
}
@end

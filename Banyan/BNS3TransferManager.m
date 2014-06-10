//
//  BNS3TransferManager.m
//  Banyan
//
//  Created by Devang Mundhra on 3/19/14.
//
//

#import "BNS3TransferManager.h"
#import "BanyanAppDelegate.h"

@implementation BNS3TransferManager


- (S3TransferOperation *) uploadData:(NSData *)data
                     withContentType:(NSString *)contentType
                         forFileName:(NSString *)filename
                        successBlock:(BNS3PutSuccessfulBlock)successBlock
                       progressBlock:(BNS3PutProgressBlock)progressBlock
                          errorBlock:(BNS3PutFailedBlock)errorBlock
{
    BNS3PutObjectRequest *por = [[BNS3PutObjectRequest alloc] initWithKey:filename
                                                             inBucket:AWSS3BucketName];
    por.contentType = contentType;
    por.data        = data;
    por.requestTag = filename;
    UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [por cancel];
        [APP_DELEGATE cleanupBeforeExit];
    }];
    por.successBlock = ^(NSString *url){
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        if (successBlock) successBlock(url);
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    };
    por.progressBlock = progressBlock;
    por.failBlock = ^(NSError *error){
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        if (errorBlock) errorBlock(error);
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    };
    
    por.delegate = por;
    if (successBlock || errorBlock) {
        // Increment the activity count only if there are callbacks that can decrement the
        // activity count.
        // If the delegate paradigm is used here, then its the responsibility of the requester/delegate
        // to increment/decrement the activity counts.
        [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    }
    
    S3TransferOperation *operation = [self upload:por];
    
    [operation addObserver:por forKeyPath:@"isCancelled" options:NSKeyValueObservingOptionNew context:nil];
    [operation addObserver:por forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];

    return operation;
}

@end
//
//  BNS3PutObjectRequest.m
//  Banyan
//
//  Created by Devang Mundhra on 3/20/14.
//
//

#import "BNS3PutObjectRequest.h"

@interface BNS3PutObjectRequest ()
@end

@implementation BNS3PutObjectRequest
@synthesize successBlock = _successBlock;
@synthesize failBlock = _failBlock;

- (void)dealloc
{
    self.successBlock = nil;
    self.failBlock = nil;
}

#pragma mark KVO for S3TransferOperation via BNS3TransferManager
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"isCancelled"]) {
        if ([object isCancelled]) {
            NSError *error = [NSError errorWithDomain:BNErrorDomain code:BNErrorCodeOpCancelled userInfo:nil];
            [self.delegate request:self didFailWithError:error];
        }
    } else if ([keyPath isEqualToString:@"isFinished"]) {
        if ([object isFinished ]) {
            // Remove the KVO for this object once we are done with it
            @try {
                [object removeObserver:self forKeyPath:@"isCancelled"];
            }
            @catch (NSException * exception) {
                [BNMisc sendGoogleAnalyticsException:exception inAction:@"remove iscancelled kvo for s3operation" isFatal:NO];
            }
            @try {
                [object removeObserver:self forKeyPath:@"isFinished"];
            }
            @catch (NSException * exception) {
                [BNMisc sendGoogleAnalyticsException:exception inAction:@"remove isfinished kvo for s3operation" isFatal:NO];
            }
        }
    }
}

#pragma mark AmazonServicesRequestDelegate method
-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    BNLogInfo(@"didReceiveResponse called: %@", response);
}

-(void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data
{
    BNLogInfo(@"didReceiveData called");
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    BNLogInfo(@"didCompleteWithResponse called: %@", response);
    if (self.successBlock) {
        if ([response.request isKindOfClass:[BNS3PutObjectRequest class]]) {
            BNS3PutObjectRequest *por = (BNS3PutObjectRequest *)response.request;
            self.successBlock([por.url absoluteString]);
        }
    }
    // Release the completion blocks once the operation is over so that the related
    // resources (like Media) in the blocks are released too
    self.successBlock = nil;
    self.failBlock = nil;
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    BNLogInfo(@"didSendData called (%@): %llu - %llu / %llu", self.requestTag, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    BNLogInfo(@"didFailWithError called: %@", error);
    if (self.failBlock) {
        self.failBlock(error);
    }
    // Release the completion blocks once the operation is over so that the related
    // resources (like Media) in the blocks are released too
    self.successBlock = nil;
    self.failBlock = nil;
}

- (void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception
{
    BNLogInfo(@"didFailWithServiceException called: %@", exception);
    NSError *error = [NSError errorWithDomain:BNErrorDomain code:BNErrorCodeException userInfo:exception.userInfo];
    [self request:request didFailWithError:error];
}

@end
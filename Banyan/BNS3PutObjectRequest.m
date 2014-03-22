//
//  BNS3PutObjectRequest.m
//  Banyan
//
//  Created by Devang Mundhra on 3/20/14.
//
//

#import "BNS3PutObjectRequest.h"

@implementation BNS3PutObjectRequest
@synthesize successBlock = _successBlock;
@synthesize failBlock = _failBlock;

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
}

@end
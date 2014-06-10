//
//  BNS3TransferManager.h
//  Banyan
//
//  Created by Devang Mundhra on 3/19/14.
//
//

#import <AWSS3/AWSS3.h>
#import "BNAWSS3Client.h"
#import "BNS3PutObjectRequest.h"


@interface BNS3TransferManager : S3TransferManager

- (S3TransferOperation *) uploadData:(NSData *)data
                     withContentType:(NSString *)contentType
                         forFileName:(NSString *)filename
                        successBlock:(BNS3PutSuccessfulBlock)successBlock
                       progressBlock:(BNS3PutProgressBlock)progressBlock
                          errorBlock:(BNS3PutFailedBlock)errorBlock;

@end

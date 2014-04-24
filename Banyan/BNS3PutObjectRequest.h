//
//  BNS3PutObjectRequest.h
//  Banyan
//
//  Created by Devang Mundhra on 3/20/14.
//
//

#import <AWSS3/AWSS3.h>

typedef void (^BNS3PutSuccessfulBlock)(NSString *url);
typedef void (^BNS3PutFailedBlock)(NSError *error);

@interface BNS3PutObjectRequest : S3PutObjectRequest <AmazonServiceRequestDelegate>
@property (strong, nonatomic) BNS3PutSuccessfulBlock successBlock;
@property (strong, nonatomic) BNS3PutFailedBlock failBlock;
@end

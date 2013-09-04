//
//  BNAWSS3Client.h
//  Banyan
//
//  Created by Devang Mundhra on 8/22/13.
//
//

#import <Foundation/Foundation.h>
#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>

@interface BNAWSS3Client : NSObject

+ (void) uploadData:(NSData *)data withContentType:(NSString *)contentType
        forFileName:(NSString *)filename
inBackgroundWithBlock:(void (^)(bool succeeded, NSString *url, NSString *filename, NSError *error))block;

+ (void) deleteObjectWithFileName:(NSString *)filename inBackgroundWithBlock:(void (^)(bool succeeded, NSError *error))block;
@end

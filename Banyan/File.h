//
//  File.h
//  Banyan
//
//  Created by Devang Mundhra on 8/4/12.
//
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface File : NSObject

@property (strong, nonatomic) NSString *url;

- (id)initWithUrl:(NSString *)url;
- (BOOL) initialized;

+ (void) uploadFileForLocalURL:(NSString *)url block:(void (^)(BOOL succeeded, NSString *newURL, NSString *newName, NSError *error))successBlock errorBlock:(void (^)(NSError *error))errorBlock;
+ (void) deleteFileWithName:(NSString *)name block:(void (^)(void))successBlock errorBlock:(void (^)(NSError *error))errorBlock;

@end

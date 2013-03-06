//
//  File+Create.h
//  Banyan
//
//  Created by Devang Mundhra on 8/4/12.
//
//

#import "File.h"
#import <Parse/Parse.h>

@interface File (Create)

+ (void) uploadFileForLocalURL:(NSString *)url block:(void (^)(BOOL succeeded, NSString *newURL, NSError *error))successBlock errorBlock:(void (^)(NSError *error))errorBlock;

@end

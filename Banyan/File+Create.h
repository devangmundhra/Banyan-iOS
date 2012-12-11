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

+ (void) uploadFileForLocalURL:(NSString *)url;

@end

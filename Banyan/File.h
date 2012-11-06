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

@end

//
//  File.m
//  Banyan
//
//  Created by Devang Mundhra on 8/4/12.
//
//

#import "File.h"
#import "BanyanDataSource.h"

@implementation File

@synthesize url = _url;

- (id)initWithUrl:(NSString *)url
{
    if ((self = [super init])) {
        _url = url;
    }
    return self;
}

- (BOOL)initialized
{
    NSMutableDictionary *ht = [BanyanDataSource hashTable];
    if ([ht objectForKey:self.url]) {
        return YES;
    }
    return NO;
}

@end

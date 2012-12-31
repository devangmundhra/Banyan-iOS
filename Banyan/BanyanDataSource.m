//
//  BanyanDataSource.m
//  Banyan
//
//  Created by Devang Mundhra on 7/18/12.
//  Copyright (c) 2012 Devang Mundhra. All rights reserved.
//

#import "BanyanDataSource.h"
#import "BanyanConnection.h"
#import "UserManagementModule.h"

@implementation BanyanDataSource

static NSMutableArray *_sharedDatasource = nil;

+ (void)initialize
{
    // Notifications to handle permission controls
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogInNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogOutNotification
                                               object:nil];
}

+ (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



+ (NSMutableArray *)shared
{
    if (!_sharedDatasource) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedDatasource = [NSMutableArray array];
        });
    }
    return _sharedDatasource;
}

+ (void) setSharedDatasource:(NSArray *)array
{
    [_sharedDatasource setArray:array];
}

# pragma Storing the stories for this app
+ (void) userLoginStatusChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:BNUserLogOutNotification]) {
        [BanyanConnection resetPermissionsForStories:_sharedDatasource];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:BNDataSourceUpdatedNotification
                                                                object:self];
        });
    } else if ([[notification name] isEqualToString:BNUserLogInNotification]) {
        [self loadDataSource];
    } else {
        NSLog(@"%s Unknown notification %@", __PRETTY_FUNCTION__, [notification name]);
    }
}

+ (void) loadDataSource
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(canView == YES) OR (canContribute == YES)"];
    NSLog(@"%s loadDataSource begin", __PRETTY_FUNCTION__);

    [BanyanConnection
     loadStoriesFromBanyanWithSuccessBlock:^(NSMutableArray *retValue) {
         [retValue filterUsingPredicate:predicate];
         NSLog(@"%s loadDataSource completed", __PRETTY_FUNCTION__);
         _sharedDatasource = retValue;
         dispatch_async(dispatch_get_main_queue(), ^{
             [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
             [[NSNotificationCenter defaultCenter] postNotificationName:BNDataSourceUpdatedNotification
                                                                 object:self];
         });
     } errorBlock:^(NSError *error) {
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in fetching stories."
                                                         message:[error localizedDescription]
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
         [alert show];
         NSLog(@"Hit error: %@", error);
     }];
}

@end

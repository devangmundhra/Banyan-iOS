//
//  RemoteObject+Share.h
//  Banyan
//
//  Created by Devang Mundhra on 12/26/13.
//
//

#import "RemoteObject.h"
#import "BanyanAppDelegate.h"
#import "MBProgressHUD.h"

@interface RemoteObject (Share)
- (void) shareOnFacebookWithName:(NSString *)name
                         caption:(NSString *)caption
                     description:(NSString *)description
                           image:(UIImage *)image
                      pictureURL:(NSString *)pictureURL
                       shareLink:(NSString *)urlToShare
               completionHandler:(void (^)(NSError *error))handler;
- (void) shareOnFacebook;
- (void) performFacebookPublishAction:(void (^)(NSError *error)) action;
- (void) performFacebookUserPhotosAction:(void (^)(NSError *error)) action;
- (void) showErrorAlert:(NSError *)error;
- (void) flaggedWithMessage:(NSString *)message;
@end

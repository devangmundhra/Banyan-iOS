//
//  Media.m
//  Banyan
//
//  Created by Devang Mundhra on 4/26/13.
//
//

#import "Media.h"
#import "RemoteObject.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIImage+ResizeAdditions.h"
#import "AFParseAPIClient.h"

@implementation Media

@dynamic createdAt;
@dynamic remoteStatusNumber;
@dynamic filename;
@dynamic filesize;
@dynamic height;
@dynamic length;
@dynamic localURL;
@dynamic orientation;
@dynamic progress;
@dynamic remoteURL;
@dynamic thumbnail;
@dynamic title;
@dynamic width;
@dynamic remoteObject;

+ (Media *)newMediaForObject:(RemoteObject *)remoteObject
{
    Media *media = [[Media alloc] initWithEntity:[NSEntityDescription entityForName:@"Media"
                                                             inManagedObjectContext:[remoteObject managedObjectContext]]
                  insertIntoManagedObjectContext:[remoteObject managedObjectContext]];
    
    media.remoteObject = remoteObject;    
    return media;
}

- (void)cancelUpload
{
    
}

- (void)remove {
    [self cancelUpload];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.localURL error:&error];
    [[self managedObjectContext] deleteObject:self];
}

- (void)save {
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

- (MediaRemoteStatus)remoteStatus {
    return (MediaRemoteStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(MediaRemoteStatus)aStatus {
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus {
    switch ([remoteStatus intValue]) {
        case MediaRemoteStatusPushing:
            return NSLocalizedString(@"Uploading", @"");
            break;
        case MediaRemoteStatusFailed:
            return NSLocalizedString(@"Failed", @"");
            break;
        case MediaRemoteStatusSync:
            return NSLocalizedString(@"Uploaded", @"");
            break;
        default:
            return NSLocalizedString(@"Pending", @"");
            break;
    }
}

- (NSString *)remoteStatusText {
    return [Media titleForRemoteStatus:self.remoteStatusNumber];
}

- (void) uploadWithSuccess:(void (^)())successBlock failure:(void (^)(NSError *error))errorBlock
{
    [self save];
    self.remoteStatus = MediaRemoteStatusProcessing;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:[NSURL URLWithString:self.localURL] resultBlock:^(ALAsset *asset) {
        NSData *imageData;
        PFFile *imageFile = nil;
        
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        CGImageRef imageRef = [rep fullScreenImage]; // not fullResolutionImage
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        
        // For now, compress the image before sending.
        // When PUT API is done, compress on the server
        // TODO
        UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:[[UIScreen mainScreen] bounds].size interpolationQuality:kCGInterpolationLow];
        
        imageData = UIImageJPEGRepresentation(resizedImage, 1);
        imageFile = [PFFile fileWithData:imageData];
        self.remoteStatus = MediaRemoteStatusPushing;

        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            self.remoteURL = imageFile.url;
            self.filename = imageFile.name;
            self.remoteStatus = MediaRemoteStatusSync;
            successBlock();
        }];
    }
            failureBlock:^(NSError *error) {
                self.remoteStatus = MediaRemoteStatusFailed;
                errorBlock(error);
            }
     ];
}

- (void) deleteWitSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))errorBlock
{
    [[AFParseAPIClient sharedClient] deletePath:PARSE_API_FILES_URL(self.filename)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            self.remoteStatus = MediaRemoteStatusSync;
                                            successBlock();
                                            [self remove];
                                        }
                                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                            self.remoteStatus = MediaRemoteStatusFailed;
                                            errorBlock(error);
                                        }];
}

@end

//
//  File+Create.m
//  Banyan
//
//  Created by Devang Mundhra on 8/4/12.
//
//

#import "File+Create.h"
#import "UIImage+ResizeAdditions.h"
#import "BNOperationQueue.h"

@implementation File (Create)

+ (void) uploadFileForLocalURL:(NSString *)url
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:[NSURL URLWithString:url] resultBlock:^(ALAsset *asset) {
        NSData *imageData;
        PFFile *imageFile = nil;
        
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        CGImageRef imageRef = [rep fullScreenImage]; // not fullResolutionImage
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        
        // For now, compress the image before sending.
        // When PUT API is done, compress on the server
        // PUT_API_TODO
        UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:[[UIScreen mainScreen] bounds].size interpolationQuality:kCGInterpolationHigh];

        imageData = UIImageJPEGRepresentation(resizedImage, 1);
        imageFile = [PFFile fileWithData:imageData];
        
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                // So that we know the file has been uploaded (aka initialized)
                [[BanyanDataSource hashTable] setObject:imageFile.url forKey:url];
                [BanyanDataSource archiveHashTable];
                NSLog(@"Image saved on server");
                NETWORK_OPERATION_COMPLETE();
            } else {
                NSLog(@"%@\t%@\t%@\t%@", [error localizedDescription], [error localizedFailureReason],
                      [error localizedRecoveryOptions], [error localizedRecoverySuggestion]);
                NETWORK_OPERATION_INCOMPLETE();
            }
        }
                               progressBlock:^(int percentDone) {
                                   [[MTStatusBarOverlay sharedInstance] setProgress:percentDone/100];
                               }
         ];
    }
            failureBlock:^(NSError *error) {
                NSLog(@"***** ERROR IN FILE CREATE ***\nCan't find the asset library image");
            }
     ];
}

@end

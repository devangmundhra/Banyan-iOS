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

+ (void) uploadFileForLocalURL:(NSString *)url block:(void (^)(BOOL succeeded, NSString *newURL, NSError *error))successBlock errorBlock:(void (^)(NSError *error))errorBlock
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
        // TODO
        UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:[[UIScreen mainScreen] bounds].size interpolationQuality:kCGInterpolationLow];
        
        imageData = UIImageJPEGRepresentation(resizedImage, 1);
        imageFile = [PFFile fileWithData:imageData];
        
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            successBlock(succeeded, imageFile.url, error);
        }];
    }
            failureBlock:errorBlock
     ];
}

@end

//
//  File.m
//  Banyan
//
//  Created by Devang Mundhra on 8/4/12.
//
//

#import "File.h"
#import "BanyanDataSource.h"
#import "UIImage+ResizeAdditions.h"
#import "AFParseAPIClient.h"

@implementation File

@synthesize url = _url;

- (id)initWithUrl:(NSString *)url
{
    if ((self = [super init])) {
        _url = url;
    }
    return self;
}

+ (void) uploadFileForLocalURL:(NSString *)url block:(void (^)(BOOL succeeded, NSString *newURL, NSString *newName, NSError *error))successBlock errorBlock:(void (^)(NSError *error))errorBlock
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
            successBlock(succeeded, imageFile.url, imageFile.name, error);
        }];
    }
            failureBlock:errorBlock
     ];
}

+ (void) deleteFileWithName:(NSString *)name block:(void (^)(void))successBlock errorBlock:(void (^)(NSError *error))errorBlock
{
    [[AFParseAPIClient sharedClient] deletePath:PARSE_API_FILES_URL(name)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            successBlock();
                                        }
                                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                            errorBlock(error);
                                        }];
}
@end

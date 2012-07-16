//
//  ImageToDataTransformer.m
//  Storied
//
//  Created by Devang Mundhra on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageToDataTransformer.h"

@implementation ImageToDataTransformer


+ (BOOL)allowsReverseTransformation 
{
	return YES;
}

+ (Class)transformedValueClass 
{
	return [NSData class];
}


- (id)transformedValue:(id)value 
{
	NSData *data = UIImagePNGRepresentation(value);
	return data;
}


- (id)reverseTransformedValue:(id)value 
{
	UIImage *uiImage = [[UIImage alloc] initWithData:value];
    return uiImage;
}

@end
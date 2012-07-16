//
//  ArrayToDataTransformer.m
//  Storied
//
//  Created by Devang Mundhra on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArrayToDataTransformer.h"

@implementation ArrayToDataTransformer

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
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
	return data;
}


- (id)reverseTransformedValue:(id)value 
{
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:value];
    return array;
}

@end

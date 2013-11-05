//
//  GooglePlacesObjectToDataTransformer.m
//  Banyan
//
//  Created by Devang Mundhra on 11/3/13.
//
//

#import "GooglePlacesObjectToDataTransformer.h"
#import "GooglePlacesObject.h"

@implementation GooglePlacesObjectToDataTransformer

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
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:(NSMutableDictionary *)value];
	return data;
}


- (id)reverseTransformedValue:(id)value
{
    id object = [BNDuckTypedObject duckTypedObjectWrappingDictionary:(NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:value]];
    return object;
}

@end

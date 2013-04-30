//
//  DictionaryToDataTransformer.m
//  Banyan
//
//  Created by Devang Mundhra on 4/29/13.
//
//

#import "FBGraphObjectToDataTransformer.h"

@implementation FBGraphObjectToDataTransformer

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
    id object = [FBGraphObject graphObjectWrappingDictionary:(NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:value]];
    return object;
}

@end

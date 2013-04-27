//
//  Location.m
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import "Location.h"

@implementation Location

@synthesize isLocationEnabled, longitude, latitude, locationName;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init]) // this needs to be [super initWithCoder:aDecoder] if the superclass implements NSCoding
    {
        isLocationEnabled = [aDecoder decodeObjectForKey:@"isLocationEnabled"];
        longitude = [aDecoder decodeObjectForKey:@"longitude"];
        latitude = [aDecoder decodeObjectForKey:@"latitude"];
        locationName = [aDecoder decodeObjectForKey:@"locationName"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    // add [super encodeWithCoder:encoder] if the superclass implements NSCoding
    [encoder encodeObject:isLocationEnabled forKey:@"isLocationEnabled"];
    [encoder encodeObject:longitude forKey:@"longitude"];
    [encoder encodeObject:latitude forKey:@"latitude"];
    [encoder encodeObject:locationName forKey:@"locationName"];
}

@end

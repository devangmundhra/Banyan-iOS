//
//  Statistics.m
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import "Statistics.h"

@implementation Statistics

@synthesize numberOfLikes, numberOfViews;
@synthesize likers, viewers, viewed, liked, favourite;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init]) // this needs to be [super initWithCoder:aDecoder] if the superclass implements NSCoding
    {
        viewed = [aDecoder decodeBoolForKey:@"viewed"];
        liked = [aDecoder decodeBoolForKey:@"liked"];
        numberOfLikes = [aDecoder decodeObjectForKey:@"numberOfLikes"];
        numberOfViews = [aDecoder decodeObjectForKey:@"numberOfViews"];
        likers = [aDecoder decodeObjectForKey:@"likers"];
        viewers = [aDecoder decodeObjectForKey:@"viewers"];
        favourite = [aDecoder decodeBoolForKey:@"favourite"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    // add [super encodeWithCoder:encoder] if the superclass implements NSCoding
    [encoder encodeBool:viewed forKey:@"viewed"];
    [encoder encodeBool:liked forKey:@"liked"];
    [encoder encodeObject:numberOfLikes forKey:@"numberOfLikes"];
    [encoder encodeObject:numberOfViews forKey:@"numberOfViews"];
    [encoder encodeObject:likers forKey:@"likers"];
    [encoder encodeObject:viewers forKey:@"viewers"];
    [encoder encodeBool:favourite forKey:@"favourite"];
}

@end

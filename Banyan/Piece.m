//
//  Piece.m
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece_Defines.h"
#import "Story.h"
#import "User.h"
#import "BanyanDataSource.h"
#import "AFParseAPIClient.h"

@implementation Piece

@synthesize image = _image;
@synthesize pieceId = _pieceId;
@synthesize pieceNumber = _sceneNumber;
@synthesize text = _text;
@synthesize imageURL = _imageURL;
@synthesize author = _author;
@synthesize nextPiece = _nextScene;
@synthesize previousPiece = _previousScene;
@synthesize createdAt = _createdAt;
@synthesize updatedAt = _updatedAt;
@synthesize numberOfContributors = _numberOfContributors;
@synthesize numberOfLikes = _numberOfLikes;
@synthesize numberOfViews = _numberOfViews;
@synthesize story = _story;
@synthesize liked = _liked;
@synthesize viewed = _viewed;
@synthesize favourite = _favourite;
@synthesize initialized = _initialized;
@synthesize location = _location;
@synthesize geocodedLocation = _geocodedLocation;
@synthesize likers = _likers;
@synthesize latitude = _latitude;
@synthesize longitude = _longitude;

// Session properties
@synthesize imageChanged = _imageChanged;

- (void)setInitialized:(BOOL)initialized
{
    _initialized = initialized;
    NSLog(@"Piece: %@ is set to be initialized: %d", _pieceId, _initialized);
}

- (BOOL)initialized
{
    return _initialized;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.pieceId forKey:@"pieceId"];
    [aCoder encodeObject:self.pieceNumber forKey:PIECE_NUMBER];
    [aCoder encodeObject:self.text forKey:PIECE_TEXT];
    [aCoder encodeObject:self.imageURL forKey:PIECE_IMAGE_URL];
    [aCoder encodeObject:self.author forKey:PIECE_AUTHOR];
    [aCoder encodeConditionalObject:self.story forKey:PIECE_STORY];
    [aCoder encodeObject:self.createdAt forKey:@"createdAt"];
    [aCoder encodeObject:self.updatedAt forKey:@"updatedAt"];
    [aCoder encodeObject:self.numberOfLikes forKey:PIECE_NUM_LIKES];
    [aCoder encodeObject:self.numberOfViews forKey:PIECE_NUM_VIEWS];
    [aCoder encodeObject:self.numberOfContributors forKey:PIECE_NUM_CONTRIBUTORS];
    [aCoder encodeBool:self.liked forKey:PIECE_LIKED];
    [aCoder encodeBool:self.viewed forKey:PIECE_VIEWED];
    [aCoder encodeBool:self.favourite forKey:PIECE_FAVOURITE];
    [aCoder encodeBool:self.initialized forKey:PIECE_IS_INITIALIZED];
    [aCoder encodeObject:self.location forKey:PIECE_LOCATION];
    [aCoder encodeObject:self.geocodedLocation forKey:PIECE_GEOCODEDLOCATION];
    [aCoder encodeObject:self.likers forKey:PIECE_LIKERS];

}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super init])) {
        self.pieceId = [aDecoder decodeObjectForKey:@"pieceId"];
        self.pieceNumber = [aDecoder decodeObjectForKey:PIECE_NUMBER];
        self.text = [aDecoder decodeObjectForKey:PIECE_TEXT];
        self.imageURL = [aDecoder decodeObjectForKey:PIECE_IMAGE_URL];
        self.author = [aDecoder decodeObjectForKey:PIECE_AUTHOR];
        self.story = [aDecoder decodeObjectForKey:PIECE_STORY];
        self.createdAt = [aDecoder decodeObjectForKey:@"createdAt"];
        self.updatedAt = [aDecoder decodeObjectForKey:@"updatedAt"];
        self.numberOfLikes = [aDecoder decodeObjectForKey:PIECE_NUM_LIKES];
        self.numberOfViews = [aDecoder decodeObjectForKey:PIECE_NUM_VIEWS];
        self.numberOfContributors = [aDecoder decodeObjectForKey:PIECE_NUM_CONTRIBUTORS];
        self.liked = [aDecoder decodeBoolForKey:PIECE_LIKED];
        self.favourite = [aDecoder decodeBoolForKey:PIECE_VIEWED];
        self.viewed = [aDecoder decodeBoolForKey:PIECE_FAVOURITE];
        self.initialized = [aDecoder decodeBoolForKey:PIECE_IS_INITIALIZED];
        self.location = [aDecoder decodeObjectForKey:PIECE_LOCATION];
        self.geocodedLocation = [aDecoder decodeObjectForKey:PIECE_GEOCODEDLOCATION];
        self.likers = [aDecoder decodeObjectForKey:PIECE_LIKERS];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{Piece\n Id: %@\n Text:%@\n Story:%@ \n}",
            self.pieceId, self.text, self.story.title];
}

// Change so that Pieces can be compared
- (NSUInteger)hash
{
    return [self.pieceId hash];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToPiece:other];
}

- (BOOL)isEqualToPiece:(Piece *)piece
{
    if (self == piece)
        return YES;
    if (![self.pieceId isEqualToString:piece.pieceId])
        return NO;
    return YES;
}
@end

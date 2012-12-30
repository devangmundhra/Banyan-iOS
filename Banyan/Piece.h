//
//  Piece.h
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class Piece, Story, User;

@interface Piece : NSObject <NSCoding>

@property (strong) id image;
@property (strong) NSString * pieceId;
@property (strong) NSNumber * pieceNumber;
@property (strong) NSString * text;
@property (strong) NSString * imageURL;
@property (strong) NSString * imageName;
@property (strong) User *author;
@property (strong) NSDate * createdAt;
@property (strong) NSDate * updatedAt;
@property (strong) NSNumber * numberOfContributors;
@property (strong) NSNumber * numberOfLikes;
@property (strong) NSNumber * numberOfViews;
@property (nonatomic, strong) NSArray *likers;
@property (strong) Story *story;
@property BOOL liked;
@property BOOL favourite;
@property BOOL viewed;
@property (strong, nonatomic) NSNumber *latitude;
@property (strong, nonatomic) NSNumber *longitude;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSString *geocodedLocation;
@property BOOL initialized;
@property (strong) Piece *nextPiece;
@property (strong) Piece *previousPiece;

// Session variables. No need to archive
@property BOOL imageChanged;

- (NSString *)description;

@end

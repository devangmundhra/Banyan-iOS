//
//  Piece.h
//  Banyan
//
//  Created by Devang Mundhra on 3/26/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RemoteObject.h"

@class Story, User;

@interface Piece : RemoteObject

@property (nonatomic, retain) NSNumber * favourite;
@property (nonatomic, retain) NSString * geocodedLocation;
@property (nonatomic, retain) NSNumber * imageChanged;
@property (nonatomic, retain) NSString * imageName;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSNumber * liked;
@property (nonatomic, retain) id likers;
@property (nonatomic, retain) NSString * longText;
@property (nonatomic, retain) NSNumber * numberOfContributors;
@property (nonatomic, retain) NSNumber * numberOfLikes;
@property (nonatomic, retain) NSNumber * numberOfViews;
@property (nonatomic, retain) NSNumber * pieceNumber;
@property (nonatomic, retain) NSString * shortText;
@property (nonatomic, retain) NSNumber * viewed;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) Story *story;

+ (NSArray *)syncedPiecesInStory:(Story *)story;
+ (NSArray *)unsavedPiecesInStory:(Story *)story;

@end

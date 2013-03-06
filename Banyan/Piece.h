//
//  Piece.h
//  Banyan
//
//  Created by Devang Mundhra on 1/7/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Story, User;

@interface Piece : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSNumber * favourite;
@property (nonatomic, retain) NSString * geocodedLocation;
@property (nonatomic, retain) NSNumber * imageChanged;
@property (nonatomic, retain) NSString * imageName;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSNumber * initialized;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * liked;
@property (nonatomic, retain) id likers;
@property (nonatomic, retain) id location;
@property (nonatomic, retain) id longitude;
@property (nonatomic, retain) NSNumber * numberOfContributors;
@property (nonatomic, retain) NSNumber * numberOfLikes;
@property (nonatomic, retain) NSNumber * numberOfViews;
@property (nonatomic, retain) NSString * pieceId;
@property (nonatomic, retain) NSNumber * pieceNumber;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * viewed;
@property (nonatomic, retain) User *author;
@property (nonatomic, retain) Story *story;

@end

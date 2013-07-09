//
//  Piece.h
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RemoteObject.h"

@class Story;

@interface Piece : RemoteObject

@property (nonatomic, retain) NSString * longText;
@property (nonatomic) int16_t pieceNumber;
@property (nonatomic, retain) NSNumber * timeStamp;
@property (nonatomic, retain) NSString * shortText;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) Story *story;

+ (NSArray *)piecesFailedToBeUploaded;
+ (NSArray *)oldPiecesInStory:(Story *)story;
+ (NSArray *)unsavedPiecesInStory:(Story *)story;
+ (Piece *)pieceForStory:(Story *)story withAttribute:(NSString *)attribute asValue:(id)value;

@end

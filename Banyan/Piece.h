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
@property (nonatomic, retain) NSString * shortText;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) Story *story;

+ (NSArray *)piecesFailedToBeUploaded;
+ (NSArray *)oldPiecesInStory:(Story *)story;
+ (NSArray *)unsavedPiecesInStory:(Story *)story;
+ (NSArray *)piecesForStory:(Story *)story withAttribute:(NSString *)attribute asValue:(id)value;
+ (Piece *)pieceForStory:(Story *)story withAttribute:(NSString *)attribute asValue:(id)value;
+ (NSUInteger)numPiecesForStory:(Story *)story withAttribute:(NSString *)attribute asValue:(id)value;
@end

@interface Piece (RestKitMappings)
+ (RKEntityMapping *)pieceMappingForRKGET;
+ (RKObjectMapping *)pieceRequestMappingForRKPOST;
+ (RKEntityMapping *)pieceResponseMappingForRKPOST;
+ (RKObjectMapping *)pieceRequestMappingForRKPUT;
+ (RKEntityMapping *)pieceResponseMappingForRKPUT;
@end
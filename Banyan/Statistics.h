//
//  Statistics.h
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import <Foundation/Foundation.h>

@interface Statistics : NSManagedObject

@property (nonatomic, retain) NSNumber * viewed;
@property (nonatomic, retain) NSNumber * liked;
@property (nonatomic, retain) NSNumber * numberOfLikes;
@property (nonatomic, retain) NSNumber * numberOfViews;
@property (nonatomic, retain) id likers;
@property (nonatomic, retain) id viewers;
@property (nonatomic, retain) NSNumber * favourite;

@end

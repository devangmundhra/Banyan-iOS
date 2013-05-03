//
//  Statistics.h
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import <Foundation/Foundation.h>

@interface Statistics : NSObject <NSCoding>

@property (nonatomic) BOOL viewed;
@property (nonatomic) BOOL liked;
@property (nonatomic, strong) NSNumber * numberOfLikes;
@property (nonatomic, strong) NSNumber * numberOfViews;
@property (nonatomic, strong) NSSet * likers;
@property (nonatomic, strong) NSSet * viewers;
@property (nonatomic) BOOL favourite;

@end

//
//  Statistics.h
//  Banyan
//
//  Created by Devang Mundhra on 4/25/13.
//
//

#import <Foundation/Foundation.h>

@interface Statistics : NSObject <NSCoding>

@property (nonatomic, strong) NSNumber * viewed;
@property (nonatomic, strong) NSNumber * liked;
@property (nonatomic, strong) NSNumber * numberOfLikes;
@property (nonatomic, strong) NSNumber * numberOfViews;
@property (nonatomic, strong) NSSet * likers;
@property (nonatomic, strong) NSSet * viewers;
@property (nonatomic, strong) NSNumber * favourite;

@end

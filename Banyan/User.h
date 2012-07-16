//
//  User.h
//  Storied
//
//  Created by Devang Mundhra on 4/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Scene, Story;

@interface User : NSObject

@property (nonatomic, strong) NSDate * dateCreated;
@property (nonatomic, strong) NSString * emailAddress;
@property (nonatomic, strong) NSString * facebookKey;
@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) id profilePic;
@property (nonatomic, strong) NSString * username;
@property (nonatomic, strong) NSArray *scenes;
@property (nonatomic, strong) NSArray *stories;
@property (nonatomic, strong) NSArray *scenesLiked;
@property (nonatomic, strong) NSArray *storiesLiked;
@property (nonatomic, strong) NSArray *scenesViewed;
@property (nonatomic, strong) NSArray *storiesViewed;
@property (nonatomic, strong) NSArray *scenesFavourites;
@property (nonatomic, strong) NSArray *storiesFavourites;
- (id) initWithUsername:(NSString *)username firstName:(NSString *)firstName lastName:(NSString *)lastName name:(NSString *)name dateCreated:(NSDate *)dateCreated emailAddress:(NSString *)emailAddress facebookKey:(NSString *)facebookKey profilePic:(id)profilePic stories:(NSArray *)stories scenes:(NSArray *)scenes scenesLiked:(NSArray *)scenesLiked storiesLiked:(NSArray *)storiesLiked scenesViewed:(NSArray *)scenesViewed storiesViewed:(NSArray *)storiesViewed scenesFavourites:(NSArray *)scenesFavourites storiesFavourites:(NSArray *)storiesFavourites;

@end

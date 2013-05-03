//
//  Comment.h
//  Banyan
//
//  Created by Devang Mundhra on 4/27/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "User.h"

@class RemoteObject;

@interface Comment : NSManagedObject

@property (nonatomic, retain) User * author;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * commentID;
@property (nonatomic, retain) RemoteObject *remoteObject;

@end

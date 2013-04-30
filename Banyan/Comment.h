//
//  Comment.h
//  Banyan
//
//  Created by Devang Mundhra on 4/27/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RemoteObject;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * commentID;
@property (nonatomic, retain) RemoteObject *remoteObject;

@end

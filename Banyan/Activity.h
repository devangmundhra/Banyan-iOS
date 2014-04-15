//
//  Activity.h
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import <Foundation/Foundation.h>

@interface Activity : NSObject <NSCoding>

@property (strong, nonatomic) NSNumber *activityId;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *object;
@property (strong, nonatomic) NSString *resourceUri;

+ (Activity *) activityWithType:(NSString *)type
                         object:(NSString *)object;

+ (RKObjectMapping *)activityRequestMappingForRKPOST;
+ (RKObjectMapping *)activityResponseMappingForRKPOST;

+ (void)createActivity:(Activity *)activity withCompletionBlock:(void (^)(bool succeeded, NSString *resourceUri, NSError *error))block;
+ (void) deleteActivityAtResourceUri:(NSString *)resourceUri withCompletionBlock:(void (^)(bool succeeded, NSError *error))block;

@end

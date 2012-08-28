//
//  Activity.m
//  Banyan
//
//  Created by Devang Mundhra on 8/26/12.
//
//

#import "Activity.h"

@implementation Activity

@synthesize type = _type;
@synthesize fromUser = _fromUser;
@synthesize toUser = _toUser;
@synthesize sceneId = _sceneId;
@synthesize storyId = _storyId;

+ (Activity *) activityWithType:(NSString *)type
                       fromUser:(NSString *)fromUser
                         toUser:(NSString *)toUser
                        sceneId:(NSString *)sceneId
                        storyId:(NSString *)storyId
{
    Activity *newActivity = [[Activity alloc] init];
    newActivity.type = type;
    newActivity.fromUser = fromUser;
    newActivity.toUser = toUser;
    newActivity.sceneId = sceneId;
    newActivity.storyId = storyId;
    
    return newActivity;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.type forKey:kBNActivityTypeKey];
    [encoder encodeObject:self.fromUser forKey:kBNActivityFromUserKey];
    [encoder encodeObject:self.toUser forKey:kBNActivityToUserKey];
    [encoder encodeObject:self.sceneId forKey:kBNActivitySceneKey];
    [encoder encodeObject:self.storyId forKey:kBNActivityStoryKey];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.type = [decoder decodeObjectForKey:kBNActivityTypeKey];
        self.fromUser = [decoder decodeObjectForKey:kBNActivityFromUserKey];
        self.toUser = [decoder decodeObjectForKey:kBNActivityToUserKey];
        self.sceneId = [decoder decodeObjectForKey:kBNActivitySceneKey];
        self.storyId = [decoder decodeObjectForKey:kBNActivityStoryKey];
    }
    return self;
}

- (NSMutableDictionary *)getAttributesInDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:5];
    
    [dictionary setObject:self.type forKey:kBNActivityTypeKey];
    [dictionary setObject:self.fromUser forKey:kBNActivityFromUserKey];
    [dictionary setObject:self.toUser forKey:kBNActivityToUserKey];
    [dictionary setObject:REPLACE_NIL_WITH_NULL(UPDATED(self.sceneId)) forKey:kBNActivitySceneKey];
    [dictionary setObject:REPLACE_NIL_WITH_NULL(UPDATED(self.storyId)) forKey:kBNActivityStoryKey];
    
    return dictionary;
}

+ (void)createActivity:(Activity *)activityContext
{
    [[AFParseAPIClient sharedClient] postPath:PARSE_API_CLASS_URL(kBNActivityClassKey)
                                   parameters:[activityContext getAttributesInDictionary]
                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                          NSLog(@"Got response for adding activity %@", activityContext);
                                          NETWORK_OPERATION_COMPLETE();
                                      }
                                      failure:BN_ERROR_BLOCK_OPERATION_INCOMPLETE()];
}

+ (void)deleteActivity:(Activity *)activityContext
{
    NSDictionary *jsonDictionary = [activityContext getAttributesInDictionary];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
    
    if (!jsonData) {
        NSLog(@"NSJSONSerialization failed %@", error);
    }
    
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *getActivities = [NSMutableDictionary dictionaryWithObject:json forKey:@"where"];
    
    [[AFParseAPIClient sharedClient] getPath:PARSE_API_CLASS_URL(kBNActivityClassKey)
                                  parameters:getActivities
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         NSDictionary *response = responseObject;
                                         NSArray *activities = [response objectForKey:@"results"];
                                         for (NSUInteger i = 0; i < [activities count]; i++) {
                                             [Activity deleteActivityWithId:[[activities objectAtIndex:i] objectForKey:@"objectId"] isLast:i == [activities count]-1];
                                         }
                                     }
                                     failure:AF_PARSE_ERROR_BLOCK()];
}

+ (void) deleteActivityWithId:(NSString *)activityId isLast:(BOOL)last
{
    [[AFParseAPIClient sharedClient] deletePath:PARSE_API_OBJECT_URL(kBNActivityClassKey, activityId)
                                     parameters:nil
                                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                            NSLog(@"Activity with id %@ deleted", activityId);
                                            if (last) {
                                                NETWORK_OPERATION_COMPLETE();
                                            }
                                        }
                                        failure:BN_ERROR_BLOCK_OPERATION_INCOMPLETE()];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{Activity\n type: %@ fromUser: %@, toUser: %@, sceneId: %@, storyId: %@\n}",
            self.type, self.fromUser, self.toUser, self.sceneId, self.storyId];
}

@end

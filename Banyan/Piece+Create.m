//
//  Scene+Create.m
//  Storied
//
//  Created by Devang Mundhra on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Piece+Create.h"
#import "Piece+Edit.h"
#import "Piece_Defines.h"
#import "Story_Defines.h"
#import "AFBanyanAPIClient.h"
#import "Media.h"
#import "User.h"
#import "User_Defines.h"
#import "Story+Permissions.h"

@implementation Piece (Create)

+ (Piece *) newPieceForStory:(Story *)story
{
    Piece *piece = [[Piece alloc] initWithEntity:[NSEntityDescription entityForName:kBNPieceClassKey
                                                             inManagedObjectContext:[story managedObjectContext]]
                  insertIntoManagedObjectContext:[story managedObjectContext]];
    
    piece.story = story;
    
    return piece;
}

+ (Piece *) newPieceDraftForStory:(Story *)story
{
    Piece *piece = [self newPieceForStory:story];
    piece.remoteStatus = RemoteObjectStatusLocal;
    piece.author = [User currentUser];
    piece.createdAt = piece.updatedAt = [NSDate date];
    piece.timeStamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceReferenceDate]];
    
//    [piece save];
    
    return piece;
}

+ (void) createNewPiece:(Piece *)piece
{
    assert(piece.bnObjectId.length == 0);
    
    if (piece.remoteStatus == RemoteObjectStatusLocal) {
        [Story updateLengthAndPieceNumbers:piece.story];
    }
    
    piece.remoteStatus = RemoteObjectStatusPushing;
    
    [piece save];
    
    // If the story of the piece has not been updated yet, don't do anything. Just fail.
    // Someone else will comeback later and create this
    if (piece.story.remoteStatus != RemoteObjectStatusSync) {
        piece.remoteStatus = RemoteObjectStatusFailed;
        [piece save];
        return;
    }
    
    NSLog(@"Adding piece %@ for story %@", piece, piece.story);
    
    //    PARSE
    void (^sendInfoToStoryFollowers)(Piece *) = ^(Piece *piece) {
        Story *story = piece.story;
        NSArray *followersList = [[story storyContributors] arrayByAddingObjectsFromArray:[story storyViewers]];
        
        NSMutableArray *fbIds = [NSMutableArray arrayWithCapacity:1];
        for (NSDictionary *contributor in followersList)
        {
            if (![[contributor objectForKey:@"id"] isEqualToString:[[PFUser currentUser] objectForKey:USER_FACEBOOK_ID]])
                [fbIds addObject:[contributor objectForKey:@"id"]];
        }
        
        if ([fbIds count] == 0)
            return;
        
        // send push notifications
        
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if (types == UIRemoteNotificationTypeNone)
            return;
        
        for (NSString *fbId in fbIds)
        {
            // get the user object id corresponding to this facebook id if it exists
            NSDictionary *jsonDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                            fbId, USER_FACEBOOK_ID, nil];
            
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
            
            if (!jsonData) {
                NSLog(@"NSJSONSerialization failed %@", error);
            }
            
            NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            NSMutableDictionary *getUsersForFbId = [NSMutableDictionary dictionaryWithObject:json forKey:@"where"];
            
            [[AFParseAPIClient sharedClient] getPath:PARSE_API_USER_URL(@"")
                                          parameters:getUsersForFbId
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 NSDictionary *response = responseObject;
                                                 NSArray *users = [response objectForKey:@"results"];
                                                 NSMutableArray *channels = [NSMutableArray arrayWithCapacity:1];
                                                 for (NSDictionary *user in users)
                                                 {
                                                     NSString *channel = [NSString stringWithFormat:@"%@%@%@", [user objectForKey:@"objectId"], BNPushNotificationChannelTypeSeperator, BNAddPieceToContributedStoryPushNotification];
                                                     [channels addObject:channel];
                                                 }
                                                 NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                       [NSString stringWithFormat:@"%@ has added a new piece to the story titled %@",
                                                                        [[PFUser currentUser] objectForKey:USER_NAME], story.title], @"alert",
                                                                       [NSNumber numberWithInt:1], @"badge",
                                                                       piece.bnObjectId, @"Piece id",
                                                                       nil];
                                                 // send push notication to this user id
                                                 PFPush *push = [[PFPush alloc] init];
                                                 [push setChannels:channels];
                                                 [push setPushToAndroid:false];
                                                 [push expireAfterTimeInterval:86400];
                                                 [push setData:data];
                                                 [push sendPushInBackground];
                                                 [TestFlight passCheckpoint:@"Push notifications sent to add a new piece"];
                                             }
                                             failure:AF_PARSE_ERROR_BLOCK()];
        }
    };
    
    // Block to upload the piece
    void (^uploadPiece)(Piece *) = ^(Piece *piece) {
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        // For serializing
        RKObjectMapping *pieceRequestMapping = [RKObjectMapping requestMapping];
        [pieceRequestMapping addAttributeMappingsFromDictionary:@{@"author.userId" : @"authorId", @"story.bnObjectId" : PIECE_STORY}];
        [pieceRequestMapping addAttributeMappingsFromArray:@[PIECE_LONGTEXT, PIECE_SHORTTEXT, @"isLocationEnabled", @"timeStamp"]];
        
        RKObjectMapping *locationMapping = [RKObjectMapping requestMapping];
        [locationMapping addAttributeMappingsFromArray:@[@"id", @"category", @"name"]];
        RKObjectMapping *locationLocationMapping = [RKObjectMapping requestMapping];
        [locationLocationMapping addAttributeMappingsFromArray:@[@"street", @"city", @"state", @"country", @"zip", @"latitude", @"longitude"]];
        [locationMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationLocationMapping]];
        [pieceRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationMapping]];

        // Media, if any, should be uploaded via edit piece, not here. This is so that empty media entities are not created in the backend.
//        RKObjectMapping *mediaMapping = [RKObjectMapping requestMapping];
//        [mediaMapping addAttributeMappingsFromDictionary:@{@"remoteURL": @"url"}];
//        [mediaMapping addAttributeMappingsFromArray:@[@"filename", @"filesize", @"height", @"length", @"orientation", @"title", @"width", @"mediaType"]];
//        [pieceRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"media" toKeyPath:@"media" withMapping:mediaMapping]];
        
        RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor
                                                  requestDescriptorWithMapping:pieceRequestMapping
                                                  objectClass:[Piece class]
                                                  rootKeyPath:nil
                                                  method:RKRequestMethodPOST];
        
        RKEntityMapping *pieceResponseMapping = [RKEntityMapping mappingForEntityForName:kBNPieceClassKey
                                                                    inManagedObjectStore:[RKManagedObjectStore defaultStore]];
        [pieceResponseMapping addAttributeMappingsFromDictionary:@{
                                                                   PARSE_OBJECT_ID : @"bnObjectId",
                                                                   }];
        [pieceResponseMapping addAttributeMappingsFromArray:@[PARSE_OBJECT_CREATED_AT, PARSE_OBJECT_UPDATED_AT, PIECE_NUMBER, @"permaLink"]];
        pieceResponseMapping.identificationAttributes = @[@"bnObjectId"];
        
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:pieceResponseMapping
                                                                                                method:RKRequestMethodPOST
                                                                                           pathPattern:nil
                                                                                               keyPath:nil
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addRequestDescriptor:requestDescriptor];
        [objectManager addResponseDescriptor:responseDescriptor];
        
        [objectManager postObject:piece
                             path:BANYAN_API_CLASS_URL(@"Piece")
                       parameters:nil
                          success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              NSLog(@"Create piece successful %@", piece);
                              piece.remoteStatus = RemoteObjectStatusSync;
                              [piece save];
                              if ([piece.media count]) {
                                  // Media should be uploaded asynchronously.
                                  // So edit the piece now which will in turn upload the media.
                                  [Piece editPiece:piece];
                              }
                              if ([piece.story numberOfContributors] || [piece.story numberOfViewers]) {
                                  sendInfoToStoryFollowers(piece);
                              }
                          }
                          failure:^(RKObjectRequestOperation *operation, NSError *error) {
                              piece.remoteStatus = RemoteObjectStatusFailed;
                              [piece save];
                              NSLog(@"Error in create piece");
                          }];
    };
    
    uploadPiece(piece);
    
    // Save this story in the UserDefaults so that next time the user will add a piece here.
    [piece.story saveStoryMOIdToUserDefaults];
    [piece.story save];
}

@end

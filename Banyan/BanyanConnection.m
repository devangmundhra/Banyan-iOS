//
//  BanyanConnection.m
//  Banyan
//
//  Created by Devang Mundhra on 11/11/12.
//
//

#import "BanyanConnection.h"
#import "AFBanyanAPIClient.h"
#import "Story+Permissions.h"
#import "Story+Edit.h"
#import "Piece+Edit.h"
#import "User.h"
#import "Media.h"
#import "Story+Create.h"
#import "Piece+Create.h"

@implementation BanyanConnection

+ (void)initialize
{
    // Notifications to handle permission controls
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogInNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userLoginStatusChanged:)
                                                 name:BNUserLogOutNotification
                                               object:nil];
}

+ (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma Storing the stories for this app
+ (void) userLoginStatusChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:BNUserLogOutNotification]) {
        [self loadDataSource];
    } else if ([[notification name] isEqualToString:BNUserLogInNotification]) {
        [self loadDataSource];
    } else {
        NSLog(@"%s Unknown notification %@", __PRETTY_FUNCTION__, [notification name]);
    }
}

+ (RKPaginator *) storiesPaginator
{
    return nil;
    
    static RKPaginator *_storiesPaginator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
        [RKObjectManager setSharedManager:objectManager];
        objectManager.managedObjectStore = [RKManagedObjectStore defaultStore];
        
        // Response
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[Story storyMappingForRK]
                                                                                                method:RKRequestMethodGET
                                                                                           pathPattern:nil
                                                                                               keyPath:@"objects"
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        [objectManager addResponseDescriptor:responseDescriptor];
        
        RKObjectMapping *paginationMapping = [RKObjectMapping mappingForClass:[RKPaginator class]];
        [paginationMapping addAttributeMappingsFromDictionary:@{
                                                                @"meta.limit": @"perPage",
                                                                @"meta.offset": @"pageCount",
                                                                @"meta.total_count": @"objectCount",
                                                                }];
        [objectManager setPaginationMapping:paginationMapping];
        
        NSString *requestString = [NSString stringWithFormat:@"/api/v1/story/?offset=:offset&limit=:perPage&format=json"];
        
        _storiesPaginator = [objectManager paginatorWithPathPattern:requestString];
        _storiesPaginator.perPage = 2; // this will request /posts?page=N&per_page=2
        
        [_storiesPaginator setCompletionBlockWithSuccess:^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
            
//            // Delete all unsaved stories
//            NSArray *unsavedStories = [Story unsavedStories];
//            for (Story *story in unsavedStories) {
//                [story remove];
//            }
            
            // Delete all stories if this is the first load
            if (page == 1) {
                NSFetchRequest * allStories = [[NSFetchRequest alloc] init];
                [allStories setEntity:[NSEntityDescription entityForName:kBNStoryClassKey inManagedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext]];
                [allStories setIncludesPropertyValues:NO]; //only fetch the managedObjectID
                
                NSError * error = nil;
                NSArray * stories = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:allStories error:&error];
                //error handling goes here
                for (Story * story in stories) {
                    if ([objects containsObject:story])
                        continue;
                    [story remove];
                }
                error = nil;
                if (![[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error]) {
                    NSLog(@"Unresolved Core Data Save error %@, %@ in saving remote object", error, [error userInfo]);
                    exit(-1);
                }
            }
            
            NSArray *stories = objects;
//            // Delete stories that have been deleted on the server
//            NSArray *syncedStories =[Story syncedStories];
//            for (Story *story in syncedStories) {
//                if (![stories containsObject:story])
//                    [story remove];
//            }
            [stories enumerateObjectsUsingBlock:^(Story *story, NSUInteger idx, BOOL *stop) {
                NSArray *unsavedPieces = [Piece unsavedPiecesInStory:story];
                if (unsavedPieces.count)
                    NSLog(@"%u unsaved pieces in story :%@", unsavedPieces.count, story.title);
                for (Piece *piece in unsavedPieces) {
                    [piece remove];
                }
                story.lastSynced = [NSDate date];
                story.currentPieceNum = MAX([Piece pieceForStory:story withAttribute:@"viewedByCurUser" asValue:[NSNumber numberWithBool:FALSE]].pieceNumber, 1);
            }];
            if (page==1)
                [[NSNotificationCenter defaultCenter] postNotificationName:BNStoryListRefreshedNotification
                                                                    object:self];
            
        } failure:^(RKPaginator *paginator, NSError *error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in fetching stories."
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [[NSNotificationCenter defaultCenter] postNotificationName:BNStoryListRefreshedNotification
                                                                object:self];
            NSLog(@"Hit error: %@", error);
        }];
    });
    
    return _storiesPaginator;
}

+ (void) loadDataSource
{
//    [[self storiesPaginator] loadPage:1];
//    return;
    
    NSLog(@"%s loadDataSource begin", __PRETTY_FUNCTION__);
    
    [BanyanConnection
     loadStoriesFromBanyanWithSuccessBlock:^ {
         NSLog(@"%s loadDataSource completed", __PRETTY_FUNCTION__);
         dispatch_async(dispatch_get_main_queue(), ^{
             [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
             NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
             [userDefaults setObject:[NSDate date] forKey:BNUserDefaultsLastSuccessfulStoryUpdateTime];
             [userDefaults synchronize];
             
             [[NSNotificationCenter defaultCenter] postNotificationName:BNStoryListRefreshedNotification
                                                                 object:self];
             NSError *error = nil;
             [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext saveToPersistentStore:&error];
         });
     } errorBlock:^(NSError *error) {
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error in fetching stories."
                                                         message:[error localizedDescription]
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
         [alert show];
         [[NSNotificationCenter defaultCenter] postNotificationName:BNStoryListRefreshedNotification
                                                             object:self];
         NSLog(@"Hit error: %@", error);
     }];
}

+ (void)loadStoriesFromBanyanWithSuccessBlock:(void (^)())successBlock errorBlock:(void (^)(NSError *error))errorBlock
{
    NSString *getPath = BANYAN_API_GET_STORIES();
    
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    objectManager.managedObjectStore = [RKManagedObjectStore defaultStore];
    
    // Response
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[Story storyMappingForRK]
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:nil
                                                                                           keyPath:@"objects"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    [objectManager getObjectsAtPath:getPath
                         parameters:nil
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
//                                // Delete all unsaved stories
//                                NSArray *unsavedStories = [Story unsavedStories];
//                                for (Story *story in unsavedStories) {
//                                    [story remove];
//                                }
                                
                                NSArray *stories = [mappingResult array];
                                // Delete stories that have been deleted on the server
                                NSArray *syncedStories =[Story syncedStories];
                                for (Story *story in syncedStories) {
                                    if (![stories containsObject:story])
                                        [story remove];
                                }
                                [stories enumerateObjectsUsingBlock:^(Story *story, NSUInteger idx, BOOL *stop) {
                                    NSArray *unsavedPieces = [Piece unsavedPiecesInStory:story];
                                    if (unsavedPieces.count)
                                        NSLog(@"%u unsaved pieces in story :%@", unsavedPieces.count, story.title);
//                                    for (Piece *piece in unsavedPieces) {
//                                        [piece remove];
//                                    }
                                    story.lastSynced = [NSDate date];
                                    story.currentPieceNum = MAX([Piece pieceForStory:story withAttribute:@"viewedByCurUser" asValue:[NSNumber numberWithBool:FALSE]].pieceNumber, 1);
                                }];
                                if (successBlock)
                                    successBlock();                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                if (errorBlock)
                                    errorBlock(error);
                            }];
}

+ (void)loadPiecesForStory:(Story *)story withParams:(NSDictionary *)params completionBlock:(void (^)())completionBlock errorBlock:(void (^)(NSError *))errorBlock
{
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    objectManager.managedObjectStore = [RKManagedObjectStore defaultStore];
    
    // Response
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[Piece pieceMappingForRK]
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:nil
                                                                                           keyPath:@"result.pieces"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [objectManager addResponseDescriptor:responseDescriptor];
    
    [objectManager getObjectsAtPath:BANYAN_API_OBJECT_URL(kBNStoryClassKey, story.bnObjectId)
                         parameters:params
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                // Delete all unsaved pieces
                                NSArray *pieces = [mappingResult array];
                                if ([story isDeleted] || story.managedObjectContext == nil ) // Don't bother doing anything if story was deleted while fetching pieces
                                    return;
                                [pieces enumerateObjectsUsingBlock:^(Piece *piece, NSUInteger idx, BOOL *stop) {
                                    piece.story = story;
                                    piece.remoteStatus = RemoteObjectStatusSync;
                                    piece.lastSynced = [NSDate date];
                                }];
                                if (completionBlock)
                                    completionBlock();
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                if (errorBlock)
                                    errorBlock(error);
                            }];
}

+ (void) loadPiecesForStory:(Story *)story completionBlock:(void (^)())completionBlock errorBlock:(void (^)(NSError *error))errorBlock
{
    [self loadPiecesForStory:story
                  withParams:@{@"attributes" : @[@"pieces"]}
             completionBlock:^{
                 // By now we have got all the pieces for the story.
                 // Remove pieces which did not come as a part of this story (meaning they were deleted from the server)
                 NSArray *oldPieces =[Piece oldPiecesInStory:story];
                 for (Piece *piece in oldPieces) {
                     [piece remove];
                 }
                 completionBlock();
             }
                  errorBlock:errorBlock];
}

+ (void) loadPiecesForStory:(Story *)story atPieceNumbers:(NSArray *)pieceNumbers completionBlock:(void (^)())completionBlock errorBlock:(void (^)(NSError *error))errorBlock
{
    [self loadPiecesForStory:story withParams:@{@"pieces" : pieceNumbers}
             completionBlock:completionBlock
                  errorBlock:errorBlock];
}

+ (void) uploadFailedObjects
{
    NSArray *failedStories = [Story storiesFailedToBeUploaded];
    for (Story *story in failedStories) {
        if (NUMBER_EXISTS(story.bnObjectId))
            [Story editStory:story];
        else
            [Story createNewStory:story];
    }
    
    NSArray *failedPieces = [Piece piecesFailedToBeUploaded];
    for (Piece *piece in failedPieces) {
        if (NUMBER_EXISTS(piece.bnObjectId))
            [Piece editPiece:piece];
        else
            [Piece createNewPiece:piece];
    }
}

@end

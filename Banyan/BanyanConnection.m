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
#import "Activity.h"
#import "BanyanAppDelegate.h"

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
    [self restkitRouteInitializations];
}

+ (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void) restkitRouteInitializations
{
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:[AFBanyanAPIClient sharedClient]];
    objectManager.managedObjectStore = [RKManagedObjectStore defaultStore];
    [RKObjectManager setSharedManager:objectManager];
    
    // Story routes
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[Story class] pathPattern:@"story/" method:RKRequestMethodPOST]];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[Story class] pathPattern:@"story/:bnObjectId/?format=json" method:RKRequestMethodPUT]];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[Story class] pathPattern:@"story/:bnObjectId/?format=json" method:RKRequestMethodDELETE]];
    
    // Piece routes
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[Piece class] pathPattern:@"piece/" method:RKRequestMethodPOST]];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[Piece class] pathPattern:@"piece/:bnObjectId/?format=json" method:RKRequestMethodPUT]];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[Piece class] pathPattern:@"piece/:bnObjectId/?format=json" method:RKRequestMethodDELETE]];
    
    // Activity routes
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[Activity class] pathPattern:@"activity/" method:RKRequestMethodPOST]];
    
    // Named routes
    [objectManager.router.routeSet addRoute:[RKRoute routeWithName:@"get_stories" pathPattern:@"story/?format=json" method:RKRequestMethodGET]];
    
    // Story descriptors
    // GET response descriptor for the route named "get_stories"
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:[Story storyMappingForRKGET]
                                                                                      method:RKRequestMethodGET
                                                                                 pathPattern:@"story/"
                                                                                     keyPath:@"objects"
                                                                                 statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    // GET response descriptor for GETting single stories
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:[Story storyMappingForRKGET]
                                                                                      method:RKRequestMethodGET
                                                                                 pathPattern:@"story/:bnObjectId/"
                                                                                     keyPath:nil
                                                                                 statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager addRequestDescriptor:[RKRequestDescriptor
                                         requestDescriptorWithMapping:[Story storyRequestMappingForRKPOST]
                                         objectClass:[Story class]
                                         rootKeyPath:nil
                                         method:RKRequestMethodPOST]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:[Story storyResponseMappingForRKPOST]
                                                                                      method:RKRequestMethodPOST
                                                                                 pathPattern:@"story/"
                                                                                     keyPath:nil
                                                                                 statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager addRequestDescriptor:[RKRequestDescriptor
                                         requestDescriptorWithMapping:[Story storyRequestMappingForRKPUT]
                                         objectClass:[Story class]
                                         rootKeyPath:nil
                                         method:RKRequestMethodPUT]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:[Story storyResponseMappingForRKPUT]
                                                                                      method:RKRequestMethodPUT
                                                                                 pathPattern:@"story/:bnObjectId/"
                                                                                     keyPath:nil
                                                                                 statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];

    // Piece descriptors
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:[Piece pieceMappingForRKGET]
                                                                                      method:RKRequestMethodGET
                                                                                 pathPattern:nil
                                                                                     keyPath:@"result.pieces"
                                                                                 statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager addRequestDescriptor:[RKRequestDescriptor
                                         requestDescriptorWithMapping:[Piece pieceRequestMappingForRKPOST]
                                         objectClass:[Piece class]
                                         rootKeyPath:nil
                                         method:RKRequestMethodPOST]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:[Piece pieceResponseMappingForRKPOST]
                                                                                      method:RKRequestMethodPOST
                                                                                 pathPattern:@"piece/"
                                                                                     keyPath:nil
                                                                                 statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    [objectManager addRequestDescriptor:[RKRequestDescriptor
                                         requestDescriptorWithMapping:[Piece pieceRequestMappingForRKPUT]
                                         objectClass:[Piece class]
                                         rootKeyPath:nil
                                         method:RKRequestMethodPUT]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:[Piece pieceResponseMappingForRKPUT]
                                                                                      method:RKRequestMethodPUT
                                                                                 pathPattern:@"piece/:bnObjectId/"
                                                                                     keyPath:nil
                                                                                 statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    
    // Activity descriptors
    [objectManager addRequestDescriptor:[RKRequestDescriptor
                                         requestDescriptorWithMapping:[Activity activityRequestMappingForRKPOST]
                                         objectClass:[Activity class]
                                         rootKeyPath:nil
                                         method:RKRequestMethodPOST]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:[Activity activityResponseMappingForRKPOST]
                                                                                      method:RKRequestMethodPOST
                                                                                 pathPattern:@"activity/"
                                                                                     keyPath:nil
                                                                                 statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]];
    
    // Fetch request blocks for deleting orphaned objects
    [objectManager addFetchRequestBlock:^NSFetchRequest *(NSURL *URL) {
        RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:@"story"];
        
        NSDictionary *argsDict = nil;
        BOOL match = [pathMatcher matchesPattern:[URL relativePath] tokenizeQueryStrings:YES parsedArguments:&argsDict];
        if (match) {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kBNStoryClassKey];
//            // Don't delete stories or pieces that have not yet been uploaded completely.
//            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (SUBQUERY(pieces, $piece, $piece.remoteStatusNumber != %@).@count = 0)",
//                                      [NSNumber numberWithInt:RemoteObjectStatusSync], [NSNumber numberWithInt:RemoteObjectStatusSync]];
            // Don't delete stories or pieces that have not yet been uploaded completely.
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@)", [NSNumber numberWithInt:RemoteObjectStatusSync]];
            [fetchRequest setPredicate:predicate];
            return fetchRequest;
        }
        
        return nil;
    }];
}

# pragma Storing the stories for this app
+ (void) userLoginStatusChanged:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:BNUserLogOutNotification]) {
        [self loadDataSource:notification];
    } else if ([[notification name] isEqualToString:BNUserLogInNotification]) {
        [self loadDataSource:notification];
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
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[Story storyMappingForRKGET]
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

+ (void) loadDataSource:(id)sender
{
//    [[self storiesPaginator] loadPage:1];
//    return;
    
    // If this refresh is by a notification, only do it if it has been atleast 15 seconds since the last refresh
    if ([sender isKindOfClass:[NSNotification class]] && ([[(NSNotification *)sender name] isEqualToString:UIApplicationDidBecomeActiveNotification])) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastSyncDate = [userDefaults objectForKey:BNUserDefaultsLastSuccessfulStoryUpdateTime];
        if (lastSyncDate && [[NSDate date] timeIntervalSinceDate:lastSyncDate]<15) {
            NSLog(@"%s loadDataSource skipped because last sync date (%@) - now (%@) < 15", __PRETTY_FUNCTION__, lastSyncDate, [NSDate date]);
            [[NSNotificationCenter defaultCenter] postNotificationName:BNStoryListRefreshedNotification
                                                                object:self];
            return;
        }
    }
    
//    if ([RemoteObject numRemoteObjectsWithPendingChanges]) {
//        // If the notification is through any kind of notification, ignore showing the alert
//        if (![sender isKindOfClass:[NSNotification class]]) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot refresh stories"
//                                                            message:@"Some of the changes that you have done are still being uploaded.\rPlease refresh the stories once all the changes have been synchronized."
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//            [alert show];
//        }
//        [[NSNotificationCenter defaultCenter] postNotificationName:BNStoryListRefreshedNotification
//                                                            object:self];
//        NSLog(@"%s loadDataSource skipped because upload in progress", __PRETTY_FUNCTION__);
//
//        return;
//    }
    
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
         });
     } errorBlock:^(NSError *error) {
         if ([[error localizedDescription] rangeOfString:@"Cocoa error 1600"].location != NSNotFound) {
             /*
              * If this is a Cocoa error 1600 error, just bail out of the app.
              * This error happens because of the following scenario, but no solution seems to be able to fix this-
              * 1. Create a story in the simulator
              * 2. Refresh the story list on the device so that you get the story
              * 3. Delete the story from the simulator, so that the story is deleted from the backend
              * 4. Refresh the story list on the device. While the story list is being refreshed, open the "addAPiece" view controller
              * 5. When the story list refresh completes, we get the Cocoa error 1600. Doing any kind of CoreData operation after that crashes the app
              * This is supposed to be fairly rare, so it is OK for now to do this until the users behaviors dictate otherwise
              */
             NSAssert(false, @"Got Unresolved Cocoa error 1600");
         }
         
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
    [[RKObjectManager sharedManager] getObjectsAtPathForRouteNamed:@"get_stories" object:nil
                                                        parameters:nil
                                                           success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                               NSArray *stories = [mappingResult array];
                                                               [stories enumerateObjectsUsingBlock:^(Story *story, NSUInteger idx, BOOL *stop) {
                                                                   story.lastSynced = [NSDate date];
                                                                   story.currentPieceNum = MAX([Piece pieceForStory:story withAttribute:@"viewedByCurUser" asValue:[NSNumber numberWithBool:FALSE]].pieceNumber, 1);
                                                               }];
                                                               if (successBlock)
                                                                   successBlock();
                                                           }
                                                           failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                               if (errorBlock)
                                                                   errorBlock(error);
                                                           }];
}

+ (void)loadPiecesForStory:(Story *)story withParams:(NSDictionary *)params completionBlock:(void (^)())completionBlock errorBlock:(void (^)(NSError *))errorBlock
{
    NSAssert(false, @"Not implemented yet");
    [[RKObjectManager sharedManager] getObjectsAtPath:nil
                                           parameters:params
                                              success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                  // Delete all unsaved pieces
                                                  NSArray *pieces = [mappingResult array];
                                                  if ([story hasBeenDeleted] || story.managedObjectContext == nil ) // Don't bother doing anything if story was deleted while fetching pieces
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
        if (NUMBER_EXISTS(story.bnObjectId)) {
            [Story editStory:story];
        }
        else {
            [Story createNewStory:story];
        }
    }
    
    NSArray *failedPieces = [Piece piecesFailedToBeUploaded];
    for (Piece *piece in failedPieces) {
        if (NUMBER_EXISTS(piece.bnObjectId)) {
            [Piece editPiece:piece];
        }
        else {
            [Piece createNewPiece:piece];
        }
    }
}

@end

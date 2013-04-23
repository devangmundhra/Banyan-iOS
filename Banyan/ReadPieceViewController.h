//
//  ReadSceneViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Piece_Defines.h"
#import "Story_Defines.h"
#import "Story+Edit.h"
#import "BanyanAppDelegate.h"
#import "UIImageView+AFNetworking.h"
#import <Parse/Parse.h>
#import "User_Defines.h"
#import "InvitedTableViewController.h"

@class ReadPieceViewController;

@protocol ReadPieceViewControllerDelegate <NSObject>

- (BOOL)readPieceViewControllerFlipToPiece:(NSNumber *)pieceNumber;

@end

@interface ReadPieceViewController : UIViewController <InvitedTableViewControllerDelegate>

@property (strong, nonatomic) Piece *piece;
@property (weak, nonatomic) IBOutlet id <ReadPieceViewControllerDelegate> delegate;

- (id) initWithPiece:(Piece *)piece;

@end
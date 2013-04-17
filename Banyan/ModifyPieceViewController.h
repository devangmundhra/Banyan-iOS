//
//  ModifyPieceViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Piece.h"
#import "Story.h"
#import "BNFBLocationManager.h"
#import "LocationPickerButton.h"
#import "MediaPickerViewController.h"
#import "MediaPickerButton.h"

@class  ModifyPieceViewController;

typedef enum {ModifyPieceViewControllerEditModeAddPiece, ModifyPieceViewControllerEditModeEditPiece} ModifyPieceViewControllerEditMode;

//@protocol ModifyPieceViewControllerDelegate <NSObject>
//
//@optional
//- (void) modifyPieceViewControllerDeletedPiece:(ModifyPieceViewController *)controller;
//
//- (void) modifyPieceViewController:(ModifyPieceViewController *)controller
//             didFinishEditingPiece:(Piece *)piece;
//
//- (void) modifyPieceViewController:(ModifyPieceViewController *)controller
//              didFinishAddingPiece:(Piece *)piece;
//
//- (void) modifyPieceViewControllerDeletedStory:(ModifyPieceViewController *)controller;
//
//@end

@interface ModifyPieceViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UINavigationBarDelegate, UIActionSheetDelegate, BNFBLocationManagerDelegate, LocationPickerButtonDelegate, MediaPickerViewControllerDelegate, MediaPickerButtonDelegate>

@property (strong, nonatomic) Piece *piece;
//@property (weak, nonatomic) id <ModifyPieceViewControllerDelegate> delegate;

- (id) initWithPiece:(Piece *)piece;

@end

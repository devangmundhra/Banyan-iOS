//
//  ModifyPieceViewController.h
//  Storied
//
//  Created by Devang Mundhra on 3/17/12.
//  Copyright (c) 2012 Banyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Piece.h"
#import "Story.h"
#import "BNFBLocationManager.h"
#import "LocationPickerButton.h"
#import "SingleImagePickerButton.h"
#import "BNAudioRecorder.h"
#import "StoryPickerViewController.h"
#import "MediaPickerViewController.h"

@class  ModifyPieceViewController;

typedef enum {ModifyPieceViewControllerEditModeAddPiece, ModifyPieceViewControllerEditModeEditPiece} ModifyPieceViewControllerEditMode;

@protocol ModifyPieceViewControllerDelegate <NSObject>

- (void) modifyPieceViewController:(ModifyPieceViewController *)controller
              didFinishAddingPiece:(Piece *)piece;

@end

@interface ModifyPieceViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, BNFBLocationManagerDelegate, LocationPickerButtonDelegate, StoryPickerViewControllerDelegate>

@property (strong, nonatomic) Piece *piece;
@property (weak, nonatomic) id <ModifyPieceViewControllerDelegate> delegate;

- (id) initWithPiece:(Piece *)piece;

@end

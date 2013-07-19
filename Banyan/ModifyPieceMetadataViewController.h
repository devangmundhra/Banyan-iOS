//
//  ModifyPieceMetadataViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 7/12/13.
//
//

#import <UIKit/UIKit.h>
#import "BNFBLocationManager.h"
#import "LocationPickerButton.h"
#import "TITokenField.h"
#import "Piece.h"
#import "Story.h"
#import "Media.h"

@protocol ModifyPieceMetadataViewControllerDelegate <NSObject>

- (Piece *)piece;
- (void) done;

@end

@interface ModifyPieceMetadataViewController : UIViewController <BNFBLocationManagerDelegate, LocationPickerButtonDelegate, TITokenFieldDelegate>

@property (weak, nonatomic) id<ModifyPieceMetadataViewControllerDelegate> delegate;

- (id) initWithDelegate:(id<ModifyPieceMetadataViewControllerDelegate>)delegate;

@end

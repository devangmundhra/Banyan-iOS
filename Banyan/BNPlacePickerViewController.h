//
//  BNPlacePickerViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 4/15/13.
//
//

#import <FacebookSDK/FacebookSDK.h>

@interface BNPlacePickerViewController : FBPlacePickerViewController <UISearchBarDelegate>

@property (nonatomic, weak) id <FBPlacePickerDelegate> delegate;

@end

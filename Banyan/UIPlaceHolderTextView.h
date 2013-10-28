//
//  UIPlaceHolderTextView.h
//  Banyan
//
//  Created by Devang Mundhra on 10/26/13.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface UIPlaceHolderTextView : UITextView

@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end

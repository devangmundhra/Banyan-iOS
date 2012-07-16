//
//  ModifySceneViewController.m
//  Storied
//
//  Created by Devang Mundhra on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModifySceneViewController.h"
#import "Scene+Create.h"
#import "Scene+Edit.h"
#import "Scene+Delete.h"
#import "Story+Delete.h"
#import "Story+Edit.h"
#import "Scene_Defines.h"
#import "Story_Defines.h"
#import "UIImageView+AFNetworking.h"
#import "UIImage+SizeAndOrientation.h"

@interface ModifySceneViewController ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *sceneTextView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *modifyImageButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteSceneButton;
@property (weak, nonatomic) IBOutlet UIToolbar *keyboardToolbar;

@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

@property (nonatomic) BOOL keyboardIsShown;
@property (nonatomic) BOOL imageChanged;
@property (nonatomic) NSUInteger contentViewDispositionOnKeyboard;

@end

@implementation ModifySceneViewController

#define MAX_CHAR_IN_SCENE 160

@synthesize contentView = _contentView;
@synthesize imageView = _imageView;
@synthesize sceneTextView = _sceneTextView;
@synthesize navigationBar = _navigationBar;
@synthesize cancelButton = _cancelButton;
@synthesize doneButton = _doneButton;
@synthesize modifyImageButton = _modifyImageButton;
@synthesize deleteSceneButton = _deleteSceneButton;
@synthesize keyboardToolbar = _keyboardToolbar;
@synthesize scene = _scene;
@synthesize delegate = _delegate;
@synthesize keyboardIsShown = _keyboardIsShown;
@synthesize editMode = _editMode;
@synthesize tapRecognizer = _tapRecognizer;
@synthesize imageChanged = _imageChanged;
@synthesize contentViewDispositionOnKeyboard = _contentViewDispositionOnKeyboard;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.sceneTextView.delegate = self;
    [self.sceneTextView.layer setCornerRadius:8];
    [self.sceneTextView setClipsToBounds:YES];
    self.sceneTextView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.navigationBar.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.scene.previousScene == nil && self.editMode != add)
        self.sceneTextView.font = [UIFont fontWithName:STORY_FONT size:24];
    else
        self.sceneTextView.font = [UIFont fontWithName:SCENE_FONT size:24];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    self.tapRecognizer.delegate = self;
    
    if (self.editMode == add)
    {
        self.navigationBar.topItem.title = @"Add Scene";
        self.deleteSceneButton.hidden = YES;
    }
    else if (self.editMode == edit)
    {
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.imageView setImageWithURL:[NSURL URLWithString:self.scene.imageURL] placeholderImage:self.scene.image];
        self.sceneTextView.text = self.scene.text;
        self.deleteSceneButton.hidden = NO;
        self.navigationBar.topItem.title = @"Edit";
    }
    
    self.sceneTextView.editable = YES;
    self.doneButton.enabled = NO;
    
    self.imageChanged = NO;
    
    [self registerForKeyboardNotifications];
    
    if (self.scene.previousScene == nil)
    {
        [self.deleteSceneButton setTitle:@"Delete Story" forState:UIControlStateNormal];
    } else {
        [self.deleteSceneButton setTitle:@"Delete Scene" forState:UIControlStateNormal];
    }
    
    CGRect keyboardToolbarFrame = self.keyboardToolbar.frame;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    keyboardToolbarFrame.origin.y = screenRect.size.height;
	self.keyboardToolbar.frame = keyboardToolbarFrame;
    self.navigationBar.translucent = YES;
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setNavigationBar:nil];
    [self setSceneTextView:nil];
    [self setCancelButton:nil];
    [self setDoneButton:nil];
    [self setModifyImageButton:nil];
    [self setDeleteSceneButton:nil];
    [self setKeyboardToolbar:nil];
    [self setContentView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    if (self.sceneTextView.isFirstResponder)
        [self.sceneTextView resignFirstResponder];
    
    [self unregisterForKeyboardNotifications];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark target actions from navigation bar

- (IBAction)cancel:(UIBarButtonItem *)sender 
{
    [self.delegate modifySceneViewControllerDidCancel:self];
}

// Done modifying scene. Now save all the changes.
- (IBAction)done:(UIBarButtonItem *)sender 
{
    if (self.editMode == add)
    {
        NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionaryWithCapacity:2];
               [mutableAttributes setObject:self.sceneTextView.text ? self.sceneTextView.text : [NSNull null]
                              forKey:SCENE_TEXT];
        [mutableAttributes setObject:self.imageView.image ? self.imageView.image : [NSNull null] 
                              forKey:SCENE_IMAGE];
        
        NSDictionary *attributes = [mutableAttributes copy];
        Scene *scene = [Scene createSceneForStory:self.scene.story attributes:attributes afterScene:self.scene];
        if (scene)
        {
            NSLog(@"New scene %@ saved", scene);
            [self.delegate modifySceneViewController:self didFinishAddingScene:scene];
            [TestFlight passCheckpoint:@"New scene created successfully"];
        } else {
            NSLog(@"Error saving new scene %@", self.sceneTextView.text);
            [TestFlight passCheckpoint:@"New scene could not be created successfully"];
        }
    }
    else if (self.editMode == edit)
    {
        if (self.scene.previousScene == nil)
        {
            NSLog(@"ModifySceneViewController_Editing story");
            self.scene.story.title = self.sceneTextView.text;
            if (self.imageChanged)
                self.scene.story.image = self.imageView.image;
            [Story editStory:self.scene.story];
        }
        self.scene.text = self.sceneTextView.text;
        if (self.imageChanged) {
            self.scene.image = self.imageView.image;
        }
        [Scene editScene:self.scene];
        [self.delegate modifySceneViewController:self didFinishEditingScene:self.scene];
    }
    else {
        NSLog(@"ModifySceneViewController_No valid edit mode");
    }
}

#define CAMERA @"Camera"
#define PHOTO_LIB @"Photo Library"
- (IBAction)modifyImage:(id)sender 
{    
    [self dismissKeyboard:sender];

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Modify Photo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:self.imageView.image ? @"Delete Photo" : nil otherButtonTitles:nil];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        [actionSheet addButtonWithTitle:CAMERA];
    [actionSheet addButtonWithTitle:PHOTO_LIB];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

- (IBAction)deleteScene:(UIButton *)sender 
{
    if (self.scene.previousScene == nil)
    {
        NSLog(@"ModifySceneViewController_Deleting story");
        [Story removeStory:self.scene.story];
        [self.delegate modifySceneViewControllerDeletedStory:self];
        [TestFlight passCheckpoint:@"Story deleted"];
    }
    else
    {
        NSLog(@"ModifySceneViewController_Deleting scene");
        [Scene removeScene:self.scene];
        [self.delegate modifySceneViewController:self];
        [TestFlight passCheckpoint:@"Scene deleted"];
    }
}

#pragma mark UIActionSheetDelegate
// Action sheet delegate method.
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        // DO NOTHING ON CANCEL
    }
    else if (buttonIndex == actionSheet.destructiveButtonIndex) {
        // MAYBE EXPLICITLY DELETE IMAGE IN FUTURE
        self.imageView.image = nil;
        self.imageChanged = YES;
        self.doneButton.enabled = [self checkForChanges];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:CAMERA]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:imagePicker animated:NO completion:nil];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:PHOTO_LIB]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else {
        NSLog(@"ModifySceneViewController_actionSheetclickedButtonAtIndex %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
    }
}

# pragma mark - Image Picker
- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    [self.imageView cancelImageRequestOperation];
    self.imageChanged = YES;
//    self.imageView.image = image;
    [NSThread detachNewThreadSelector:@selector(useImage:) toTarget:self withObject:image];
    self.doneButton.enabled = [self checkForChanges];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker 
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)useImage:(UIImage *)image {    
    // Create a graphics image context
    CGRect screenSize = [[UIScreen mainScreen] bounds];

    UIImage* newImage = [UIImage imageWithImage:image scaledToSize:screenSize.size];
    
    [self.imageView setImage:newImage];
}

# pragma mark - Keyboard notifications
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    self.keyboardIsShown = NO;
}

- (void)unregisterForKeyboardNotifications
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification 
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification 
                                                  object:nil];
    
    self.keyboardIsShown = NO;
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShown:(NSNotification*)aNotification
{
    if (self.keyboardIsShown)
        return;
    NSDictionary* info = [aNotification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [self.view addGestureRecognizer:self.tapRecognizer];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    
    CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];
    
    CGRect viewFrame = self.contentView.frame;
    self.contentViewDispositionOnKeyboard = self.sceneTextView.frame.origin.y - statusRect.size.height;
    viewFrame.origin.y -= self.contentViewDispositionOnKeyboard;
    self.contentView.frame = viewFrame;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect keyboardToolbarFrame = self.keyboardToolbar.frame;
	keyboardToolbarFrame.origin.y = screenRect.size.height - keyboardSize.height 
                                    - keyboardToolbarFrame.size.height
                                    + self.contentViewDispositionOnKeyboard;
    self.keyboardToolbar.frame = keyboardToolbarFrame;
    
    [UIView commitAnimations];
    self.keyboardIsShown = YES; 
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillHide:(NSNotification*)aNotification
{    
    
    //    NSDictionary* info = [aNotification userInfo];
    //    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if(!self.keyboardIsShown)
        return;
    
    [self.view removeGestureRecognizer:self.tapRecognizer];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    CGRect viewFrame = self.contentView.frame;
    viewFrame.origin.y += self.contentViewDispositionOnKeyboard;
    self.contentView.frame = viewFrame;
    
    CGRect keyboardToolbarFrame = self.keyboardToolbar.frame;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    keyboardToolbarFrame.origin.y = screenRect.size.height + self.contentViewDispositionOnKeyboard;
	self.keyboardToolbar.frame = keyboardToolbarFrame;
    
    [UIView commitAnimations];
    self.keyboardIsShown = NO;
    self.contentViewDispositionOnKeyboard = 0;
}

-(void)didTapAnywhere: (UITapGestureRecognizer*) recognizer {    
    [self dismissKeyboard:NULL];
}

- (IBAction)dismissKeyboard:(id)sender
{
    self.doneButton.enabled = [self checkForChanges];
    
    if (self.sceneTextView.isFirstResponder)
        [self.sceneTextView resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView 
shouldChangeTextInRange:(NSRange)range 
 replacementText:(NSString *)text
{
//    // Any new character added is passed in as the "text" parameter
//    if ([text isEqualToString:@"\n"]) {
//        // Be sure to test for equality using the "isEqualToString" message
//        [self dismissKeyboard:nil];
//        
//        // Return FALSE so that the final '\n' character doesn't get added
//        return FALSE;
//    }
    
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return (newLength > MAX_CHAR_IN_SCENE) ? NO : YES;
//    // For any other character return TRUE so that the text gets added to the view
//    return TRUE;
}

- (BOOL)checkForChanges
{
    if (self.editMode == add)
    {
        if (self.imageChanged
            || ![self.sceneTextView.text isEqualToString:@""])
            return YES;
        else
            return NO;
    } else if (self.editMode == edit)
    {
        if ((self.imageChanged)
            || (![self.sceneTextView.text isEqualToString:self.scene.text]))
            return YES;
        else
            return NO;
    } else
    {
        NSLog(@"ModifySceneViewController_checkForChanges_1");
        return NO;
    }
}

#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isDescendantOfView:self.keyboardToolbar])
        return NO;
    else {
        return YES;
    }
}

#pragma Memory Management
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end

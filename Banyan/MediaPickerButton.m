//
//  MediaPickerButton.m
//  Banyan
//
//  Created by Devang Mundhra on 4/1/13.
//
//

#import "MediaPickerButton.h"
#import "Media.h"

@interface MediaPickerButtonTableViewCell ()
@property (strong, nonatomic) UIImageView *myImageView;

@end

@implementation MediaPickerButtonTableViewCell
@synthesize media = _media;
@synthesize myImageView = _myImageView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.myImageView = [[UIImageView alloc] init];
        self.myImageView.backgroundColor = BANYAN_WHITE_COLOR;
        self.myImageView.clipsToBounds = YES;
        self.myImageView.userInteractionEnabled = NO;
        self.myImageView.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    return self;
}

@end

@interface MediaPickerButton ()
@property (nonatomic, strong) UIButton *addImageButton;
@property (nonatomic, strong) UITableView *tableView;
- (void) setup;
@end

@implementation MediaPickerButton
@synthesize addImageButton, delegate;
@synthesize tableView = _tableView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup
{    
    self.tableView = [[UITableView alloc] initWithFrame:self.bounds];
    self.tableView.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.tableView.frame = self.bounds;
    [self addSubview:self.tableView];
    self.tableView.rowHeight = CGRectGetHeight(self.bounds);
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.editing = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    
    self.clipsToBounds = YES;
    self.addImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addImageButton.transform = CGAffineTransformMakeRotation(M_PI_2);
    addImageButton.frame = CGRectMake(0, 0, CGRectGetHeight(self.bounds), CGRectGetHeight(self.bounds));
    [addImageButton.titleLabel setFont:[UIFont boldSystemFontOfSize:15.0f]];
    [addImageButton addTarget:self action:@selector(handleMediaPickerButtonTappedAdd:) forControlEvents:UIControlEventTouchUpInside];
    [addImageButton setBackgroundColor:BANYAN_GREEN_COLOR];
    UIImage *cameraImage = [UIImage imageNamed:@"cameraSymbol"];
    [addImageButton setImage:cameraImage forState:UIControlStateNormal];
    [addImageButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
    [addImageButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [addImageButton setAdjustsImageWhenHighlighted:NO];
    
    addImageButton.showsTouchWhenHighlighted = YES;
    self.tableView.tableHeaderView = addImageButton;
}

#pragma mark -
#pragma mark Table view delegate and data source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	// Number of sections is the number of regions
	return 1;
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return [self.delegate listOfMediaForMediaPickerButton].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
	
	static NSString *CellIdentifier = @"MediaPickerButtonCell";
	
	MediaPickerButtonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [self tableViewCellWithReuseIdentifier:CellIdentifier];
	}

	[self configureCell:cell forIndexPath:indexPath];
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	/*
	 To conform to the Human Interface Guidelines, selections should not be persistent --
	 deselect the row after it has been selected.
	 */
    Media *mediaToDelete = [[self.delegate listOfMediaForMediaPickerButton] objectAtIndex:indexPath.row];
    [self.delegate deletePreviousMedia:mediaToDelete];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self.delegate updateMediaFromNumber:fromIndexPath.row toNumber:toIndexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#define RESIZED_REORDER_CONTROL_VIEW_TAG 1
- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView *resizedGripView = nil;

    for (UIView *view in cell.subviews) {
        if (view.tag == RESIZED_REORDER_CONTROL_VIEW_TAG) {
            // The control for this cell has already been resized
            resizedGripView = view;
            break;
        }
    }
    
    //	Grip customization code goes in here...
    for(UIView* view in cell.subviews)
    {
        if([[[view class] description] isEqualToString:@"UITableViewCellReorderControl"])
        {
            if (!resizedGripView) {
                UIView* resizedGripView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetMaxX(view.frame), CGRectGetMaxY(view.frame))];
                resizedGripView.tag = RESIZED_REORDER_CONTROL_VIEW_TAG;
                
                [resizedGripView addSubview:view];
                [cell addSubview:resizedGripView];
                
                CGSize sizeDifference = CGSizeMake(resizedGripView.frame.size.width - view.frame.size.width, resizedGripView.frame.size.height - view.frame.size.height);
                CGSize transformRatio = CGSizeMake(resizedGripView.frame.size.width / view.frame.size.width, resizedGripView.frame.size.height / view.frame.size.height);
                
                //	Original transform
                CGAffineTransform transform = CGAffineTransformIdentity;
                
                //	Scale custom view so grip will fill entire cell
                transform = CGAffineTransformScale(transform, transformRatio.width, transformRatio.height);
                
                //	Move custom view so the grip's top left aligns with the cell's top left
                transform = CGAffineTransformTranslate(transform, -sizeDifference.width / 2.0, -sizeDifference.height / 2.0);
                
                [resizedGripView setTransform:transform];
            } else {
                // If the reorder control was already transformed, just translate it. It was already scaled earlier.
                CGAffineTransform transform = resizedGripView.transform;
                transform = CGAffineTransformScale(transform, 1/transform.a, 1/transform.d);
                [view setTransform:transform];
                [resizedGripView addSubview:view];
            }
            
            for(UIImageView* cellGrip in view.subviews)
            {
                if([cellGrip isKindOfClass:[UIImageView class]])
                    [cellGrip setImage:nil];
            }
        }
    }
}

- (MediaPickerButtonTableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier
{
	MediaPickerButtonTableViewCell *cell = [[MediaPickerButtonTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                                 reuseIdentifier:identifier];
    cell.backgroundColor = BANYAN_WHITE_COLOR;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMediaPickerButtonTappedDelete:)];
    [cell addGestureRecognizer:tap];
    
    cell.showsReorderControl = YES;
	return cell;
}

- (void)configureCell:(MediaPickerButtonTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    UIImageView *imageView = cell.myImageView;
    [cell.contentView addSubview:imageView];
    imageView.frame = CGRectMake(0, 0, CGRectGetHeight(self.bounds), CGRectGetHeight(self.bounds));
    cell.media = [[self.delegate listOfMediaForMediaPickerButton] objectAtIndex:indexPath.row];
    [cell.media getImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(CGRectGetHeight(self.bounds), CGRectGetHeight(self.bounds)) interpolationQuality:kCGInterpolationLow forMediaWithSuccess:^(UIImage *image) {[imageView setImage:image];} progress:nil failure:nil];
}

#pragma mark -
#pragma mark Instance Methods

- (void) reloadList
{
    self.tableView.editing = NO;
    [self.tableView reloadData];
    self.tableView.editing = YES;
}

- (void)handleMediaPickerButtonTappedAdd:(id)sender
{
    if (delegate) {
        [delegate addNewMedia:self];
    }
}

- (void)handleMediaPickerButtonTappedDelete:(id)sender
{
    MediaPickerButtonTableViewCell *cell = (MediaPickerButtonTableViewCell *)((UITapGestureRecognizer *)sender).view;
    
    if (delegate) {
        [delegate deletePreviousMedia:cell.media];
    }
}

@end

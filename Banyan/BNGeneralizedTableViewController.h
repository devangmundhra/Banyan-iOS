//
//  BNGeneralizedTableViewController.h
//  Banyan
//
//  Created by Devang Mundhra on 12/14/13.
//
//

#import <UIKit/UIKit.h>
#import "Story.h"

@interface BNGeneralizedTableViewController : UITableViewController

@property (strong, nonatomic) NSArray *dataSource;
typedef enum {
    BNGeneralizedTableViewTypeStoryContributors,
    BNGeneralizedTableViewTypePieceLikers,
} BNGeneralizedTableViewType;
@property (nonatomic) BNGeneralizedTableViewType type;
@property (nonatomic, copy) NSString *sectionString;

- (id)initWithStyle:(UITableViewStyle)style type:(BNGeneralizedTableViewType)type;

@end

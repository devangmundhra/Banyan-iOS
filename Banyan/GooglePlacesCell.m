//
//  GooglePlacesCell.m
//  Banyan
//
//  Created by Devang Mundhra on 11/4/13.
//
//

#import "GooglePlacesCell.h"
#import "BNLabel.h"

@interface GooglePlacesCell ()
@property (strong, nonatomic) BNLabel *placeLabel;
@property (strong, nonatomic) BNLabel *addInfoLabel;

@end

@implementation GooglePlacesCell
@synthesize placeLabel = _placeLabel;
@synthesize addInfoLabel = _addInfoLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.placeLabel = [[BNLabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), 0.6*CGRectGetHeight(self.frame))];
        self.placeLabel.textEdgeInsets = UIEdgeInsetsMake(5, 5, 0, 5);
        self.placeLabel.adjustsFontSizeToFitWidth    = YES;
        self.placeLabel.font                         = [UIFont fontWithName:@"Roboto-Bold" size:12];
        self.placeLabel.minimumScaleFactor           = 0.9;
        self.placeLabel.numberOfLines                = 4;
        self.placeLabel.lineBreakMode                = NSLineBreakByWordWrapping;
        self.placeLabel.textColor                    = BANYAN_BLACK_COLOR;
        self.placeLabel.textAlignment                = NSTextAlignmentLeft;
        [self addSubview:self.placeLabel];
        
        self.addInfoLabel = [[BNLabel alloc] initWithFrame:CGRectMake(0, 0.6*CGRectGetHeight(self.frame), CGRectGetWidth(self.frame), 0.4*CGRectGetHeight(self.frame))];
        self.addInfoLabel.textEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5);
        self.addInfoLabel.verticalTextAlignment = BNLabelVerticalTextAlignmentTop;
        self.addInfoLabel.textColor              = BANYAN_DARKGRAY_COLOR;
        self.addInfoLabel.font                   = [UIFont fontWithName:@"Roboto" size:10];
        [self addSubview:self.addInfoLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setLocation:(GooglePlacesObject<GooglePlacesObject>*)place andCurrentLocation:(CLLocation *)userLoc
{
    self.placeLabel.text                         = place.name;
    //Figure out Distance from POI and User
    CLLocation *poi = [[CLLocation alloc] initWithLatitude:[place.geometry.location.lat doubleValue]  longitude:[place.geometry.location.lng doubleValue]];
    CLLocationDistance inFeet = ([userLoc distanceFromLocation:poi]) * 3.2808;
    
    CLLocationDistance inMiles = ([userLoc distanceFromLocation:poi]) * 0.000621371192;
    
    NSString *distanceInFeet = [NSString stringWithFormat:@"%.f", round(2.0f * inFeet) / 2.0f];
    NSString *distanceInMiles = [NSString stringWithFormat:@"%.2f", inMiles];
    NSLog(@"Total Distance %@ in feet, distance in miles %@",distanceInFeet, distanceInMiles);
    
    //You can use place.distanceInMilesString or place.distanceInFeetString.
    //You can add logic that if distanceInMilesString starts with a 0. then use Feet otherwise use Miles.
    if ([distanceInMiles hasPrefix:@"0."]) {
        self.addInfoLabel.text = [NSString stringWithFormat:@"%@ feet from current location", distanceInFeet];
    } else {
        self.addInfoLabel.text = [NSString stringWithFormat:@"%@ miles from current location", distanceInMiles];
    }
}

@end

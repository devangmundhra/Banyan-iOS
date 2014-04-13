//
//  GooglePlacePickerTableViewCell.m
//  Banyan
//
//  Created by Devang Mundhra on 4/12/14.
//
//

#import "GooglePlacePickerTableViewCell.h"
#import <GoogleMaps/GoogleMaps.h>

@interface GooglePlacePickerTableViewCell ()

@property (weak, nonatomic) GMSMarker *marker;

@end

@implementation GooglePlacePickerTableViewCell

@synthesize marker = _marker;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.textLabel.font = [UIFont fontWithName:@"Roboto" size:12.0];
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.marker.map = nil;
    self.textLabel.textColor = BANYAN_BLACK_COLOR;
}

- (void)setWithName:(NSString *)name place:(GooglePlacesObject<GooglePlacesObject> *)place color:(UIColor *)color markOnMap:(BOOL)markOnMap
{
    self.textLabel.text = name;
    if (color)
        self.textLabel.textColor = color;
    if (markOnMap)
        self.marker = [self.delegate addMarkerAtPlace:place withColor:color];
}

@end

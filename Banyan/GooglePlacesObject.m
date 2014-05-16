//
//  GooglePlacesObject.m
//  Banyan
//
//  Created by Devang Mundhra on 12/8/12.
//
//

#import "GooglePlacesObject.h"

@implementation GooglePlacesObject

@synthesize placesId;
@synthesize reference;
@synthesize name;
@synthesize icon;
@synthesize rating;
@synthesize vicinity;
@synthesize types;
@synthesize url;
@synthesize address_components;
@synthesize formatted_address;
@synthesize formatted_phone_number;
@synthesize website;
@synthesize international_phone_number;
@synthesize geometry;

+ (NSMutableDictionary<BNDuckTypedObject> *)duckTypedObject
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@{@"location": @{}} forKey:@"geometry"];
    NSMutableDictionary<BNDuckTypedObject> *object = [BNDuckTypedObject duckTypedObjectWrappingDictionary:dict];
    return object;
}

# pragma mark Helper functions
- (NSString *)getFormattedName
{
    if (!self)
        return nil;
    return [NSString stringWithFormat:@"%@, %@", self.name, self.vicinity];
}

@end

@interface GooglePlacesAutocompletePlace()
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *reference;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic) GooglePlacesAutocompletePlaceType type;
@end

@implementation GooglePlacesAutocompletePlace

@synthesize name;
@synthesize reference;
@synthesize identifier;


+ (GooglePlacesAutocompletePlace *)placeFromDictionary:(NSDictionary *)placeDictionary
{
    GooglePlacesAutocompletePlace *place = [[self alloc] init];
    place.name = placeDictionary[@"description"];
    place.reference = placeDictionary[@"reference"];
    place.identifier = placeDictionary[@"id"];
    place.type = placeTypeFromDictionary(placeDictionary);
    return place;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Name: %@, Reference: %@, Identifier: %@, Type: %@",
            self.name, self.reference, self.identifier, placeTypeStringForPlaceType(self.type)];
}

GooglePlacesAutocompletePlaceType placeTypeFromDictionary(NSDictionary *placeDictionary) {
    return [placeDictionary[@"types"] containsObject:@"establishment"] ? PlaceTypeEstablishment : PlaceTypeGeocode;
}

NSString *placeTypeStringForPlaceType(GooglePlacesAutocompletePlaceType type) {
    return (type == PlaceTypeGeocode) ? @"geocode" : @"establishment";
}

@end
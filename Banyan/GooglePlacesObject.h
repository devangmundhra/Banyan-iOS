//
//  GooglePlacesObject.h
//  Banyan
//
//  Created by Devang Mundhra on 12/8/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BNDuckTypedObject.h"

#define	kAccounting	@"accounting"
#define	kAirport	@"airport"
#define	kAmusementPark	@"amusement_park"
#define	kAquarium	@"aquarium"
#define	kArtGallery	@"art_gallery"
#define	kAtm	@"atm"
#define	kBakery	@"bakery"
#define	kBank	@"bank"
#define	kBar	@"bar"
#define	kBeautySalon	@"beauty_salon"
#define	kBicycleStore	@"bicycle_store"
#define	kBookStore	@"book_store"
#define	kBowlingAlley	@"bowling_alley"
#define	kBusStation	@"bus_station"
#define	kCafe	@"cafe"
#define	kCampground	@"campground"
#define	kCarDealer	@"car_dealer"
#define	kCarRental	@"car_rental"
#define	kCarRepair	@"car_repair"
#define	kCarWash	@"car_wash"
#define	kCasino	@"casino"
#define	kCemetery	@"cemetery"
#define	kChurch	@"church"
#define	kCityHall	@"city_hall"
#define	kClothingStore	@"clothing_store"
#define	kConvenienceStore	@"convenience_store"
#define	kCourthouse	@"courthouse"
#define	kDentist	@"dentist"
#define	kDepartmentStore	@"department_store"
#define	kDoctor	@"doctor"
#define	kElectrician	@"electrician"
#define	kElectronicsStore	@"electronics_store"
#define	kEmbassy	@"embassy"
#define	kEstablishment	@"establishment"
#define	kFinance	@"finance"
#define	kFireStation	@"fire_station"
#define	kFlorist	@"florist"
#define	kFood	@"food"
#define	kFuneralHome	@"funeral_home"
#define	kFurnitureStore	@"furniture_store"
#define	kGasStation	@"gas_station"
#define	kGeneralContractor	@"general_contractor"
#define	kGeocode	@"geocode"
#define	kGrocerySupermarket	@"grocery_or_supermarket"
#define	kGym	@"gym"
#define	kHairCare	@"hair_care"
#define	kHardwareStore	@"hardware_store"
#define	kHealth	@"health"
#define	kHindu_temple	@"hindu_temple"
#define	kHomeGoodsStore	@"home_goods_store"
#define	kHospital	@"hospital"
#define	kInsuranceAgency	@"insurance_agency"
#define	kJewelryStore	@"jewelry_store"
#define	kLaundry	@"laundry"
#define	kLawyer	@"lawyer"
#define	kLibrary	@"library"
#define	kLiquorStore	@"liquor_store"
#define	kLocalGovernmentOffice	@"local_government_office"
#define	kLocksmith	@"locksmith"
#define	kLodging	@"lodging"
#define	kMealDelivery	@"meal_delivery"
#define	kMealTakeaway	@"meal_takeaway"
#define	kMosque	@"mosque"
#define	kMovieTental	@"movie_rental"
#define	kMovieTheater	@"movie_theater"
#define	kMovingCompany	@"moving_company"
#define	kMuseum	@"museum"
#define	kNightClub	@"night_club"
#define	kPainter	@"painter"
#define	kPark	@"park"
#define	kParking	@"parking"
#define	kPetStore	@"pet_store"
#define	kPharmacy	@"pharmacy"
#define	kPhysiotherapist	@"physiotherapist"
#define	kPlaceWorship	@"place_of_worship"
#define	kPlumber	@"plumber"
#define	kPolice	@"police"
#define	kPostOffice	@"post_office"
#define	kRealEstateAgency	@"real_estate_agency"
#define	kRestaurant	@"restaurant"
#define	kRoofingContractor	@"roofing_contractor"
#define	kRvPark	@"rv_park"
#define	kSchool	@"school"
#define	kShoeStore	@"shoe_store"
#define	kShoppingMall	@"shopping_mall"
#define	kSpa	@"spa"
#define	kStadium	@"stadium"
#define	kStorage	@"storage"
#define	kStore	@"store"
#define	kSubwayStation	@"subway_station"
#define	kSynagogue	@"synagogue"
#define	kTaxiStand	@"taxi_stand"
#define	kTrainStation	@"train_station"
#define	kTravelAgency	@"travel_agency"
#define	kUniversity	@"university"
#define	kVeterinaryCare	@"veterinary_care"
#define	kZoo	@"zoo"

@protocol GooglePlacesObject;
@class GooglePlacesObject;

@protocol GoogleLocationObject <BNDuckTypedObject>

@property (strong, nonatomic) NSNumber *lat;
@property (strong, nonatomic) NSNumber *lng;

@end

@protocol GoogleGeoObject <BNDuckTypedObject>
@property (nonatomic, strong) id<GoogleLocationObject> location;
@end

@protocol GooglePlacesObject <BNDuckTypedObject>

@property (nonatomic, strong) NSString    *placesId;
@property (nonatomic, strong) NSString    *reference;
@property (nonatomic, strong) NSString    *name;
@property (nonatomic, strong) NSString    *icon;
@property (nonatomic, strong) NSString    *rating;
@property (nonatomic, strong) NSString    *vicinity;
@property (nonatomic, strong) NSArray     *types;
@property (nonatomic, strong) NSString    *url;
@property (nonatomic, strong) NSArray     *address_components;
@property (nonatomic, strong) NSString    *formatted_address;
@property (nonatomic, strong) NSString    *formatted_phone_number;
@property (nonatomic, strong) NSString    *website;
@property (nonatomic, strong) NSString    *international_phone_number;
@property (nonatomic, assign) id<GoogleGeoObject> geometry;

@end

@interface GooglePlacesObject : BNDuckTypedObject <GooglePlacesObject>

- (NSString *)getFormattedName;

@end

#pragma 
#pragma GooglePlacesAutocompletePlace
@interface GooglePlacesAutocompletePlace : NSObject
+ (GooglePlacesAutocompletePlace *)placeFromDictionary:(NSDictionary *)placeDictionary;

/*!
 Contains the human-readable name for the returned result. For establishment results, this is usually the business name.
 */
@property (nonatomic, strong, readonly) NSString *name;

typedef enum {
    PlaceTypeInvalid = -1,
    PlaceTypeGeocode = 0,
    PlaceTypeEstablishment
} GooglePlacesAutocompletePlaceType;
/*!
 Contains the primary 'type' of this place (i.e. "establishment" or "gecode").
 */
@property (nonatomic, readonly) GooglePlacesAutocompletePlaceType type;

/*!
 Contains a unique token that you can use to retrieve additional information about this place in a Place Details request. You can store this token and use it at any time in future to refresh cached data about this Place, but the same token is not guaranteed to be returned for any given Place across different searches.
 */
@property (nonatomic, strong, readonly) NSString *reference;

/*!
 Contains a unique stable identifier denoting this place. This identifier may not be used to retrieve information about this place, but can be used to consolidate data about this Place, and to verify the identity of a Place across separate searches.
 */
@property (nonatomic, strong, readonly) NSString *identifier;

@end
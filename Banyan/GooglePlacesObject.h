//
//  GooglePlacesObject.h
//  Banyan
//
//  Created by Devang Mundhra on 12/8/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

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

#define kGOOGLE_API_KEY @"AIzaSyBwOBP068EO-Ubi0Qzu8uwFnZZHaIVwNyg"

@interface GooglePlacesObject : NSObject
{
    NSString    *placesId;
    NSString    *reference;
    NSString    *name;
    NSString    *icon;
    NSString    *rating;
    NSString    *vicinity;
    NSArray     *type;
    NSString    *url;
    NSArray     *addressComponents;
    NSString    *formattedAddress;
    NSString    *formattedPhoneNumber;
    NSString    *website;
    NSString    *internationalPhoneNumber;
    NSString    *searchTerms;
    CLLocationCoordinate2D coordinate;

    NSString    *distanceInFeetString;
    NSString    *distanceInMilesString;
    
}

@property (nonatomic, strong) NSString    *placesId;
@property (nonatomic, strong) NSString    *reference;
@property (nonatomic, strong) NSString    *name;
@property (nonatomic, strong) NSString    *icon;
@property (nonatomic, strong) NSString    *rating;
@property (nonatomic, strong) NSString    *vicinity;
@property (nonatomic, strong) NSArray     *type;
@property (nonatomic, strong) NSString    *url;
@property (nonatomic, strong) NSArray     *addressComponents;
@property (nonatomic, strong) NSString    *formattedAddress;
@property (nonatomic, strong) NSString    *formattedPhoneNumber;
@property (nonatomic, strong) NSString    *website;
@property (nonatomic, strong) NSString    *internationalPhoneNumber;
@property (nonatomic, strong) NSString      *searchTerms;
@property (nonatomic, assign) CLLocationCoordinate2D    coordinate;

@property (nonatomic, strong) NSString    *distanceInFeetString;
@property (nonatomic, strong) NSString    *distanceInMilesString;

- (id)initWithJsonResultDict:(NSDictionary *)jsonResultDict andUserCoordinates:(CLLocationCoordinate2D)userCoords;
- (id)initWithJsonResultDict:(NSDictionary *)jsonResultDict searchTerms:(NSString *)terms andUserCoordinates:(CLLocationCoordinate2D)userCoords;

- (id)initWithName:(NSString *)name
          latitude:(double)lt
         longitude:(double)lg
         placeIcon:(NSString *)icn
            rating:(NSString *)rate
          vicinity:(NSString *)vic
              type:(NSString *)typ
         reference:(NSString *)ref
               url:(NSString *)www
 addressComponents:(NSString *)addComp
  formattedAddress:(NSArray *)fAddrss
formattedPhoneNumber:(NSString *)fPhone
           website:(NSString *)web
internationalPhone:(NSString *)intPhone
       searchTerms:(NSString *)search
    distanceInFeet:(NSString *)distanceFeet
   distanceInMiles:(NSString *)distanceMiles;
- (NSString *)getFormattedName;

@end

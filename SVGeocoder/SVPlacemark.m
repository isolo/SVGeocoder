//
// SVPlacemark.m
// SVGeocoder
//
// Created by Sam Vermette on 01.05.11.
// Copyright 2011 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVGeocoder
//

#import "SVPlacemark.h"

@interface SVPlacemark ()

@property (nonatomic, strong, readwrite) NSString *formattedAddress;
@property (nonatomic, strong, readwrite) NSString *subThoroughfare;
@property (nonatomic, strong, readwrite) NSString *thoroughfare;
@property (nonatomic, strong, readwrite) NSString *subLocality;
@property (nonatomic, strong, readwrite) NSString *locality;
@property (nonatomic, strong, readwrite) NSString *subAdministrativeArea;
@property (nonatomic, strong, readwrite) NSString *administrativeArea;
@property (nonatomic, strong, readwrite) NSString *administrativeAreaCode;
@property (nonatomic, strong, readwrite) NSString *postalCode;
@property (nonatomic, strong, readwrite) NSString *country;
@property (nonatomic, strong, readwrite) NSString *ISOcountryCode;

@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite) MKCoordinateRegion region;
@property (nonatomic, strong, readwrite) CLLocation *location;

@end


@implementation SVPlacemark

@synthesize formattedAddress, subThoroughfare, thoroughfare, subLocality, locality, subAdministrativeArea, administrativeArea, administrativeAreaCode, postalCode, country, ISOcountryCode, coordinate, location, region;

- (id)initWithDictionary:(NSDictionary *)result {
    
    if(self = [super init]) {
        self.formattedAddress = [result objectForKey:@"formatted_address"];
        
        NSArray *addressComponents = [result objectForKey:@"address_components"];
        
        [addressComponents enumerateObjectsUsingBlock:^(NSDictionary *component, NSUInteger idx, BOOL *stopAddress) {
            NSArray *types = [component objectForKey:@"types"];
            
            if([types containsObject:@"street_number"])
                self.subThoroughfare = [component objectForKey:@"long_name"];
            
            if([types containsObject:@"route"])
                self.thoroughfare = [component objectForKey:@"long_name"];
            
            if([types containsObject:@"administrative_area_level_3"] || [types containsObject:@"sublocality"] || [types containsObject:@"neighborhood"])
                self.subLocality = [component objectForKey:@"long_name"];
            
            if([types containsObject:@"locality"])
                self.locality = [component objectForKey:@"long_name"];
            
            if([types containsObject:@"administrative_area_level_2"])
                self.subAdministrativeArea = [component objectForKey:@"long_name"];
            
            if([types containsObject:@"administrative_area_level_1"]) {
                self.administrativeArea = [component objectForKey:@"long_name"];
                self.administrativeAreaCode = [component objectForKey:@"short_name"];
            }
            
            if([types containsObject:@"country"]) {
                self.country = [component objectForKey:@"long_name"];
                self.ISOcountryCode = [component objectForKey:@"short_name"];
            }
            
            if([types containsObject:@"postal_code"])
                self.postalCode = [component objectForKey:@"long_name"];
            
        }];
        
        NSDictionary *locationDict = [[result objectForKey:@"geometry"] objectForKey:@"location"];
        NSDictionary *boundsDict = [[result objectForKey:@"geometry"] objectForKey:@"bounds"];
        NSDictionary *viewportDict = [[result objectForKey:@"geometry"] objectForKey:@"viewport"];
        
        CLLocationDegrees lat = [[locationDict objectForKey:@"lat"] doubleValue];
        CLLocationDegrees lng = [[locationDict objectForKey:@"lng"] doubleValue];
        self.coordinate = CLLocationCoordinate2DMake(lat, lng);
        self.location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        
        NSDictionary *northEastDict = [boundsDict objectForKey:@"northeast"];
        NSDictionary *southWestDict = [boundsDict objectForKey:@"southwest"];
        
        struct Bounds bounds = self.bounds;
        
        bounds.northEastLatitude = [[northEastDict objectForKey:@"lat"] doubleValue];
        bounds.southWestLatitude = [[southWestDict objectForKey:@"lat"] doubleValue];
        bounds.northEastLongitude = [[northEastDict objectForKey:@"lng"] doubleValue];
        bounds.southWestLongitude = [[southWestDict objectForKey:@"lng"] doubleValue];
        
        self.bounds = bounds;
        
        NSDictionary *northEastVDict = [viewportDict objectForKey:@"northeast"];
        NSDictionary *southWestVDict = [viewportDict objectForKey:@"southwest"];
        
        struct Bounds viewport = self.viewport;
        
        viewport.northEastLatitude  = [[northEastVDict objectForKey:@"lat"] doubleValue];
        viewport.southWestLatitude  = [[southWestVDict objectForKey:@"lat"] doubleValue];
        viewport.northEastLongitude = [[northEastVDict objectForKey:@"lng"] doubleValue];
        viewport.southWestLongitude = [[southWestVDict objectForKey:@"lng"] doubleValue];
        
        self.viewport = viewport;
        
        CLLocationDegrees latitudeDelta = fabs(self.bounds.northEastLatitude - self.bounds.southWestLatitude);
        
        CLLocationDegrees longitudeDelta = fabs(self.bounds.northEastLongitude - self.bounds.southWestLongitude);
        MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
        self.region = MKCoordinateRegionMake(self.location.coordinate, span);
    }
    
    return self;
}

- (NSString *)name {
    if(self.subThoroughfare && self.thoroughfare)
        return [NSString stringWithFormat:@"%@ %@", self.subThoroughfare, self.thoroughfare];
    else if(self.thoroughfare)
        return self.thoroughfare;
    else if(self.subLocality)
        return self.subLocality;
    else if(self.locality)
        return [NSString stringWithFormat:@"%@, %@", self.locality, self.administrativeAreaCode];
    else if(self.administrativeArea)
        return self.administrativeArea;
    else if(self.country)
        return self.country;
    return nil;
}

- (NSString*)description {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          formattedAddress, @"formattedAddress",
                          subThoroughfare?subThoroughfare:[NSNull null], @"subThoroughfare",
                          thoroughfare?thoroughfare:[NSNull null], @"thoroughfare",
                          subLocality?subLocality:[NSNull null], @"subLocality",
                          locality?locality:[NSNull null], @"locality",
                          subAdministrativeArea?subAdministrativeArea:[NSNull null], @"subAdministrativeArea",
                          administrativeArea?administrativeArea:[NSNull null], @"administrativeArea",
                          postalCode?postalCode:[NSNull null], @"postalCode",
                          country?country:[NSNull null], @"country",
                          ISOcountryCode?ISOcountryCode:[NSNull null], @"ISOcountryCode",
                          [NSString stringWithFormat:@"%f, %f", self.coordinate.latitude, self.coordinate.longitude], @"coordinate",
                          nil];
    
	return [dict description];
}

@end

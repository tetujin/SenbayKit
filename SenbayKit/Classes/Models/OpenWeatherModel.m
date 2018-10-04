//
//  WeatherData.m
//  VQR
//
//  Created by Yuuki Nishiyama on 2014/12/02.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import "OpenWeatherModel.h"

@implementation OpenWeatherModel
{
    double thisLat;
    double thisLon;
    NSDate * thisDate;
    NSString * apiURL;
    
    //// keys ///////
    NSString* KEY_SYS;
    NSString* ELE_COUNTORY;
    /** weather */
    NSString* KEY_WEATHER;;
    NSString* ELE_MAIN;
    NSString* ELE_DESCRIPTION;;
    /** main */
    NSString* KEY_MAIN;
    NSString* ELE_TEMP;
    NSString* ELE_TEMP_MAX;
    NSString* ELE_TEMP_MIN;
    NSString* ELE_HUMIDITY;
    NSString* ELE_PRESSURE;
    /** wind */
    NSString* KEY_WIND;
    NSString* ELE_SPEED;
    NSString* ELE_DEG;
    /** rain */
    NSString* KEY_RAIN;
    NSString* ELE_3H;
    /** clouds */
    NSString* KEY_CLOUDS;
    NSString* ELE_ALL;
    /** city */
    NSString* KEY_NAME;
    
    NSString* ZERO;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _apiKey = @"ca1dcad96d56efb9bba476ee37bfbdbe";
        apiURL  = OWM_API_URL;
        _latestWeatherData = [[NSDictionary alloc] init];
        [self initKeys];
    }
    return self;
}

- (instancetype)initWithAPIKey:(NSString *)apiKey
{
    self = [super init];
    if (self != nil) {
        _apiKey = apiKey;
        apiURL  = OWM_API_URL;
        _latestWeatherData = [[NSDictionary alloc] init];
        [self initKeys];
    }
    return self;
}

- (void) initKeys
{
    KEY_SYS         = @"sys";
    ELE_COUNTORY    = @"country";
    /** weather */
    KEY_WEATHER     = @"weather";
    ELE_MAIN        = @"main";
    ELE_DESCRIPTION = @"description";
    /** main */
    KEY_MAIN        = @"main";
    ELE_TEMP        = @"temp";
    ELE_TEMP_MAX    = @"temp_max";
    ELE_TEMP_MIN    = @"temp_min";
    ELE_HUMIDITY    = @"humidity";
    ELE_PRESSURE    = @"pressure";
    /** wind */
    KEY_WIND        = @"wind";
    ELE_SPEED       = @"speed";
    ELE_DEG         = @"deg";
    /** rain */
    KEY_RAIN        = @"rain";
    ELE_3H          = @"3h";
    /** clouds */
    KEY_CLOUDS      = @"clouds";
    ELE_ALL         = @"all";
    /** city */
    KEY_NAME        = @"name";
    
    ZERO            = @"0";
}

- (void)updateWeatherWithLat:(double)lat
                         lon:(double)lon
                      hadler:(OpenWeatherDataUpdateResultHandler)handler
{
    _updateResultHandler = handler;
    thisDate = [NSDate new];
    thisLat = lat;
    thisLon = lon;
    if( lat !=0  &&  lon != 0){
        [self getWeatherJSONStr:lat lon:lon];
    }
}

- (void) getWeatherJSONStr:(double)lat
                       lon:(double)lon
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        //APIからtokenを取得
        NSString *url = [NSString stringWithFormat:self->apiURL, (int)lat, (int)lon, self->_apiKey];
        
        //リクエストを生成
        NSMutableURLRequest *request;
        request = [[NSMutableURLRequest alloc] init];
        [request setHTTPMethod:@"GET"];
        [request setURL:[NSURL URLWithString:url]];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setTimeoutInterval:20];
        [request setHTTPShouldHandleCookies:FALSE];
        //[request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
        
        NSURLSessionDataTask* task = [session dataTaskWithURL:[NSURL URLWithString:url]
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                       if (error != nil) {
                           self->_updateResultHandler(nil, data, error);
                           return;
                       }
                       self->_receivedDate = data;
                       //取得したレスポンスをJSONパース
                       NSError *e = nil;
                       NSDictionary * parsedData = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:NSJSONReadingAllowFragments
                                                                           error:&e];
                       
                       if(e != nil){
                           self->_updateResultHandler(parsedData, data, e);
                       }else{
                           self->_latestWeatherData = parsedData;
                           self->_updateResultHandler(parsedData, data, nil);
                       }
                   });
               }];
        [task resume];

    }];
}

- (NSString *) getCountry
{
    NSString* value = [[_latestWeatherData valueForKey:KEY_SYS] valueForKey:ELE_COUNTORY];
    if(value != nil){
        return value;
    }else{
        return @"0";
    }
}

- (NSString *) getWeather
{
    @try {
        return [[[_latestWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_MAIN];
    } @catch (NSException *exception) {
        return @"";
    }
}

- (NSString *) getWeatherDescription
{
    @try {
        return [[[_latestWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_DESCRIPTION];

    } @catch (NSException *exception) {
        return @"";
    }
}

- (NSNumber *) getTemperature
{
    @try {
        return [self convertKelToCel:[[_latestWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP]] ;
    } @catch (NSException *exception) {
        return nil;
    }
}

- (NSNumber *) getTemperatureMax
{
    @try {
        return [self convertKelToCel:[[_latestWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP_MAX]];
    } @catch (NSException *exception) {
        return nil;
    }

}

- (NSNumber *) getTemperatureMin
{
    @try {
        return [self convertKelToCel:[[_latestWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP_MIN]];
    } @catch (NSException *exception) {
        return nil;
    }
}

- (NSNumber *) getHumidity
{
    @try {
        return @([[[_latestWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_HUMIDITY] doubleValue]);
    } @catch (NSException *exception) {
        return nil;
    }
}

- (NSNumber *) getAirPressure
{
    @try {
        return @([[[_latestWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_PRESSURE] doubleValue]);
    } @catch (NSException *exception) {
        return nil;
    }
}

- (NSNumber *) getWindSpeed
{
    @try {
        return @([[[_latestWeatherData valueForKey:KEY_WIND] valueForKey:ELE_SPEED] doubleValue]);
    } @catch (NSException *exception) {
        return nil;
    }
}

- (NSNumber *) getWindDegree
{
    @try {
        return @([[[_latestWeatherData valueForKey:KEY_WIND] valueForKey:ELE_DEG] doubleValue]);
    } @catch (NSException *exception) {
        return nil;
    }
}

- (NSNumber *) getRain
{
    @try {
        return @([[[_latestWeatherData valueForKey:KEY_RAIN] valueForKey:ELE_3H] doubleValue]);
    } @catch (NSException *exception) {
        return nil;
    }
}

- (NSNumber *) getClouds
{
    @try {
        return @([[[_latestWeatherData valueForKey:KEY_CLOUDS] valueForKey:ELE_ALL] doubleValue]);
    } @catch (NSException *exception) {
        return nil;
    }
}

- (NSString *) getName
{
    @try {
        return [_latestWeatherData valueForKey:KEY_NAME];
    } @catch (NSException *exception) {
        return @"";
    }
}

- (NSNumber *) convertKelToCel:(NSString *) kelStr {
    //return kelStr;
    if(kelStr != nil){
        double kel = kelStr.doubleValue;
        return @(kel-273.15);
    }else{
        return nil;
    }
}

- (bool) isNotNil
{
    if(_latestWeatherData==nil){
        return false;
    }else{
        return true;
    }
}

- (bool) isNil
{
    if(_latestWeatherData==nil){
        return true;
    }else{
        return false;
    }
}

- (bool) isOld:(int)gap
{
    NSDate *now = [NSDate date];
    NSTimeInterval delta = [now timeIntervalSinceDate:thisDate]; // => 例えば 500.0 秒後
    if(delta > gap){
        return true;
    }else{
        return false;
    }
}

- (NSString *)description
{
    return [_latestWeatherData description];
}

@end

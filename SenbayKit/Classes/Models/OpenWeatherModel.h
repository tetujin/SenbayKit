//
//  WeatherData.h
//  VQR
//
//  Created by Yuuki Nishiyama on 2014/12/02.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import <Foundation/Foundation.h>


//sample: ca1dcad96d56efb9bba476ee37bfbdbe
#define OWM_API_URL @"https://api.openweathermap.org/data/2.5/weather?lat=%d&lon=%d&APPID=%@";

typedef void (^OpenWeatherDataUpdateResultHandler)(NSDictionary * _Nullable resultDict, NSData * _Nullable resultData, NSError * _Nullable error);

@interface OpenWeatherModel : NSObject

@property NSDictionary * latestWeatherData;
@property NSData *       receivedDate;
@property NSString * apiKey;
@property OpenWeatherDataUpdateResultHandler updateResultHandler;

- (instancetype) initWithAPIKey:(NSString*)apiKey;
- (void) updateWeatherWithLat:(double)lat lon:(double)lon hadler:(OpenWeatherDataUpdateResultHandler) handler;
- (NSString *) getCountry;
- (NSString *) getWeather;
- (NSString *) getWeatherDescription;
- (NSString *) getName;
- (NSString *) description;

- (NSNumber *) getTemperature;
- (NSNumber *) getTemperatureMax;
- (NSNumber *) getTemperatureMin;
- (NSNumber *) getHumidity;
- (NSNumber *) getAirPressure;
- (NSNumber *) getWindSpeed;
- (NSNumber *) getWindDegree;
- (NSNumber *) getRain;
- (NSNumber *) getClouds;

@end

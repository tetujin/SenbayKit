//
//  SenbayOpenWeatherMap.h
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/09/22.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "SenbaySensor.h"
#import "OpenWeatherModel.h"

@interface SenbayOpenWeatherMap : SenbaySensor<CLLocationManagerDelegate>

@property CLLocationManager * locationManager;

@property int refreshInterval;
@property NSString * apiKey;
@property double updateInterval;

- (void) activate;
- (void) deactivate;

@end

//
//  SenbayBattery.h
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import <Foundation/Foundation.h>
#import "SenbaySensor.h"

@interface SenbayBattery : SenbaySensor

- (void) activate;
- (void) deactivate;

@end

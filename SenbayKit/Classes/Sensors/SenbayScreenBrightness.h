//
//  SenbayScreenBrightness.h
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import <Foundation/Foundation.h>
#import "SenbaySensor.h"

@interface SenbayScreenBrightness : SenbaySensor

- (void) activate;
- (void) deactivate;

@end

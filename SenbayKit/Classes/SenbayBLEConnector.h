//
//  SenbayBLEConnector.h
//  SenbayKit-ObjC
//
//  Created by Yuuki Nishiyama on 2018/09/18.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "SenbayBLE.h"

@interface SenbayBLEConnector : NSObject <CBPeripheralDelegate, CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableService *service;
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;

- (void) start;
- (void) stop;

- (void) setLastestData:(NSString *)latestData;

@end

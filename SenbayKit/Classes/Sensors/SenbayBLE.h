//
//  SenbayBLE.h
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import <Foundation/Foundation.h>
#import "SenbaySensor.h"

@import CoreBluetooth;

// HR Sensor
#define POLARH7_HRM_DEVICE_INFO_SERVICE_UUID              @"180A"
#define POLARH7_HRM_HEART_RATE_SERVICE_UUID               @"180D"
#define POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID       @"2A37"
#define POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID     @"2A38"
#define POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID @"2A29"

#define SENBAY_BLE_TAG_SERVICE_UUID                    @"DD9FD42C-F357-4028-ABFB-E1BF12015B0A"
#define SENBAY_BLE_TAG_LATEST_DATS_CHARACTERISTIC_UUID @"BE54F50F-135A-46EE-8DD8-399ECD249C35"
#define SENBAY_EVENT_BLETAG_DID_RECEIVED_DATA          @"senbay.event.bletag.didreceiveddata"

@interface SenbayBLE : SenbaySensor <CBCentralManagerDelegate, CBPeripheralDelegate>

@property CBPeripheral * bleTagPeripheral;

// BLE objects and methods
@property (nonatomic, strong) CBCentralManager * cbCentralManager;
@property (nonatomic, strong) CBPeripheral     * hrCBPeripheral;

- (void) activateHRM;
- (void) deactivatHRM;

- (void) activateBLETag;
- (void) deactivateBLETag;

@end

//
//  SenbayBLEConnector.m
//  SenbayKit-ObjC
//
//  Created by Yuuki Nishiyama on 2018/09/18.
//

#import "SenbayBLEConnector.h"

@implementation SenbayBLEConnector
{
    CBCharacteristic *bleTagCharacteristic;
    NSString * data;
}

- (instancetype)init
{
    self = [super init];
    if (self!=nil) {

    }
    return self;
}

- (void) start
{
    // init a peripheral manager
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                 queue:nil
                                                               options:nil];
}

- (void) stop
{
    if (_peripheralManager!=nil) {
        [_peripheralManager stopAdvertising];
    }
}

/**
 *
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    /**  Generate a service UUID for advertising data */
    CBUUID *myCustomCharacteristicUUID = [CBUUID UUIDWithString:SENBAY_BLE_TAG_LATEST_DATS_CHARACTERISTIC_UUID];
    _characteristic = [[CBMutableCharacteristic alloc] initWithType:myCustomCharacteristicUUID
                                                           properties:CBCharacteristicPropertyRead|CBCharacteristicPropertyNotify
                                                                value:nil
                                                          permissions:CBAttributePermissionsReadable];
    /** Add an advertisement service to a peripheral manager */
    CBUUID *myCustomServiceUUID = [CBUUID UUIDWithString:SENBAY_BLE_TAG_SERVICE_UUID];
    _service = [[CBMutableService alloc] initWithType:myCustomServiceUUID primary:YES];
    _service.characteristics = @[_characteristic];
    [_peripheralManager addService:_service];
    
    /** Start advertising services */
    [_peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[_service.UUID],
                                             CBAdvertisementDataLocalNameKey:@"BLE Tag"}];
}

/**
 *
 */
- (void) peripheralManager:(CBPeripheralManager *)peripheral
             didAddService:(CBService *)service
                     error:(NSError *)error
{
    NSLog(@"add a service: %@", service.description);
    if(error){
        NSLog(@"get an error when added a service: %@",[error localizedDescription]);
    }
}


/**
 *
 */
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"start advertising a service: %@", peripheral.description);
    if(!error){
        NSLog(@"get an error when a peripheral manager did start advertising a service: %@", error.debugDescription);
    }
    
}

/**
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic %@", characteristic);
    
    // save charactraistic
    bleTagCharacteristic = characteristic;
    
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request
{
    // Peripheral側のCBCentralオブジェクトでMTUを確認する
    NSLog(@"Received read request: MTU=%zd", request.central.maximumUpdateValueLength);
    
    // Read Response
    if ([request.characteristic.UUID isEqual:_characteristic.UUID]) {
        if (data!=nil) {
            request.value = [data dataUsingEncoding:NSUTF8StringEncoding];
            [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
        }else{
            [peripheral respondToRequest:request withResult:CBATTErrorRequestNotSupported];
        }
    } else {
        [peripheral respondToRequest:request withResult:CBATTErrorRequestNotSupported];
    }
}

/**
 *
 */
- (void) setLastestData:(NSString *)latestData
{
    data = latestData;
    
    if(bleTagCharacteristic != nil && data!=nil){
        [_peripheralManager updateValue:[data dataUsingEncoding:NSUTF8StringEncoding]
                      forCharacteristic:_characteristic
                     onSubscribedCentrals:nil];
    }
}


//- (void) peripheralManager:(CBPeripheralManager *) peripheral
//didReceiveReadRequest:(CBATTRequest *)request
//{
//    NSLog(@"receive read request");
//    //NSData *data = [@"0,0,0" dataUsingEncoding:NSUTF8StringEncoding];
//    request.value = [self getSensorData];
//    [_myPeripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
//}


//- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
//{
//    for (CBATTRequest *rqs in requests) {
//        if ([_myCharacteristic isEqual:rqs.characteristic])
//        {
//            NSString * strGotValue = [[NSString alloc] initWithData:rqs.value encoding:NSUTF8StringEncoding];
//            [_myPeripheralManager respondToRequest:rqs
//                                         withResult:CBATTErrorSuccess];
//        }
//    }
//}


- (NSString *)generateRandomStr:(int)length
{
    NSString *chars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJLKMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomStr = [NSMutableString string];
    for (int i=0; i<length; i++) {
        int index = arc4random_uniform((int)chars.length);
        [randomStr appendString:[chars substringWithRange:NSMakeRange(index, 1)]];
    }
    return randomStr;
}



@end

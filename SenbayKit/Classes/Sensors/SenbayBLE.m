//
//  SenbayBLE.m
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2018/09/13.
//

#import "SenbayBLE.h"

@implementation SenbayBLE
{
    NSString * hr;
    NSString * bleTagRawData;
    BOOL isHRMActive;
    BOOL isBLETagActive;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {

    }
    return self;
}

- (void)activateHRM
{
    isHRMActive = YES;
    if (_cbCentralManager == nil) {
        _cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
}

- (void)deactivatHRM
{
    isHRMActive = NO;
    if (_cbCentralManager!=nil) [_cbCentralManager stopScan];
    _cbCentralManager = nil;
}

- (void)activateBLETag
{
    isBLETagActive = YES;
    if (_cbCentralManager == nil) {
        _cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
}

- (void)deactivateBLETag
{
    isBLETagActive = NO;
    if (_cbCentralManager!=nil) [_cbCentralManager stopScan];
    _cbCentralManager = nil;
}

- (NSString *)getData
{
    NSMutableString * data = [[NSMutableString alloc] init];
    if (isHRMActive && hr != nil) {
        [data appendFormat:@"HTBT:%@,",hr];
    }
    
    if (isBLETagActive && bleTagRawData != nil) {
        [data appendFormat:@"BTAG:'%@',",bleTagRawData];
    }
    
    if (data.length > 0) {
        [data deleteCharactersInRange:NSMakeRange(data.length-1, 1)];
        return data;
    }
    
    return nil;
}


/**
 * BLE 関係の処理
 * http://www.raywenderlich.com/52080/introduction-core-bluetooth-building-heart-rate-monitor
 */
//====================================
#pragma mark - CBCentralManagerDelegate

// bool alertState = NO;

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if([central state] == CBManagerStatePoweredOff){
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }else if([central state] == CBManagerStatePoweredOn){
        NSLog(@"CoreBluetooth BLE hardware is powered on");
        [self restartBLEScan];
    }else if([central state] == CBManagerStateUnauthorized){
        NSLog(@"CoreBluetooth BLE hardware is unauthorized");
    }else if([central state] == CBManagerStateUnknown){
        NSLog(@"CoreBluetooth BLE hardware is unknown");
    }else if([central state] == CBManagerStateResetting){
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}

- (void) restartBLEScan
{
    NSArray *services = @[
                          [CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID],
                          [CBUUID UUIDWithString:POLARH7_HRM_DEVICE_INFO_SERVICE_UUID],
                          [CBUUID UUIDWithString:SENBAY_BLE_TAG_SERVICE_UUID]
                          ];
    // [self.centralManager retrieveConnectedPeripheralsWithServices:services];
    [_cbCentralManager scanForPeripheralsWithServices:services options:nil];
}


///////////////////////////////////////

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    
    [peripheral setDelegate:self];
    NSMutableArray * uuids = [[NSMutableArray alloc] init];
    for (CBUUID * uuid in peripheral.services) {
        [uuids addObject:uuid];
    }
    [peripheral discoverServices:uuids];
}

//////////////////////////////////////////

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSString * localName = [advertisementData objectForKeyedSubscript:CBAdvertisementDataLocalNameKey];
    NSArray  * services  = (NSArray *)[advertisementData objectForKeyedSubscript:CBAdvertisementDataServiceUUIDsKey];
    
    // NSString *serviceUUID = [NSString stringWithFormat:@"%@",[localUUIDArray objectAtIndex:0]];
    for (CBUUID * service in services) {
        /** --------- Senbay -------- */
        if([service isEqual:[CBUUID UUIDWithString:SENBAY_BLE_TAG_SERVICE_UUID]]){
            NSString *iOSSensorText = [NSString stringWithFormat:NSLocalizedString(@"%@に接続しますか？", @"ble title"), localName];
            UIAlertController *iOSSensorAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"外部センサが見つかりました", @"additional ble message") message:iOSSensorText preferredStyle:UIAlertControllerStyleAlert];
            UIViewController *baseView = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (baseView.presentedViewController != nil && !baseView.presentedViewController.isBeingDismissed) {
                baseView = baseView.presentedViewController;
            }
            // YES
            [iOSSensorAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"はい",@"ble yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                self->_bleTagPeripheral = peripheral;
                peripheral.delegate = self;
                [self->_cbCentralManager connectPeripheral:peripheral options:nil];
            }]];
            // NO
            [iOSSensorAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"いいえ",@"ble no") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];
            // Completion
            [baseView presentViewController:iOSSensorAlertController animated:YES completion:^{
            }];
            
        }else if([service isEqual:[CBUUID UUIDWithString:POLARH7_HRM_HEART_RATE_SERVICE_UUID]]){
            NSString *messageText = [NSString stringWithFormat:NSLocalizedString(@"%@に接続しますか？", @"ble title"), localName];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"心拍センサが見つかりました", @"ble message") message:messageText preferredStyle:UIAlertControllerStyleAlert];
            // YES
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"はい",@"ble yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                self->_hrCBPeripheral = peripheral;
                peripheral.delegate = self;
                [self->_cbCentralManager connectPeripheral:peripheral options:nil];
            }]];
            // NO
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"いいえ",@"ble no") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];
            UIViewController *baseView = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (baseView.presentedViewController != nil && !baseView.presentedViewController.isBeingDismissed) {
                baseView = baseView.presentedViewController;
            }
            [baseView presentViewController:alertController animated:YES completion:^{
            }];
        }
    }
}


//=================================
#pragma mark - BPeripheralDelegate
//=================================
- (void) peripheral:(CBPeripheral *) peripheral
didDiscoverServices:(NSError *)error
{
    for(CBService *service in peripheral.services){
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void) peripheral:(CBPeripheral *) peripheral
didDiscoverCharacteristicsForService:(CBService *)service
              error:(NSError *)error
{
    // Retrieve Device Information Services for the Manufacturer Name
    if ([service.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_DEVICE_INFO_SERVICE_UUID]])  { // 4
        for (CBCharacteristic *aChar in service.characteristics) {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID]]) {
                [self->_hrCBPeripheral readValueForCharacteristic:aChar];
            }
        }
    }
    
    // Retrieve Device Information Services for the Manufacturer Name
    if ([service.UUID isEqual:[CBUUID UUIDWithString:SENBAY_BLE_TAG_SERVICE_UUID]])  { // 4
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SENBAY_BLE_TAG_LATEST_DATS_CHARACTERISTIC_UUID]]) {
                [self->_bleTagPeripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}


- (CBCharacteristic *) getCharateristicWithUUID:(NSString *)uuid
                                           from:(CBService *) cbService
{
    for (CBCharacteristic *characteristic in cbService.characteristics) {
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:uuid]]){
            return characteristic;
        }
    }
    
    return nil;
}

- (void) peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
              error:(NSError *)error
{
    // NSLog(@"Name:%@, Identifier:%@, Characteristic:%@", peripheral.name, peripheral.identifier, characteristic.UUID.UUIDString);
    //////////////////////////////////////////////////////////////////////////////
    // HeartRate Sensor
    // Updated value for heart rate measurement received
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MEASUREMENT_CHARACTERISTIC_UUID]]) { // 1
        // Get the Heart Rate Monitor BPM
        [self setHeartBPMData:characteristic error:error];
    }
    // Retrieve the characteristic value for manufacturer name received
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID]]) {  // 2
        [self setManufacturerName:characteristic];
    }
    // Retrieve the characteristic value for the body sensor location received
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:POLARH7_HRM_BODY_LOCATION_CHARACTERISTIC_UUID]]) {  // 3
        [self setBodyLocation:characteristic];
    }
    
    //////////////////////////////////////////////////////////////////
    // BLE Tag
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:SENBAY_BLE_TAG_LATEST_DATS_CHARACTERISTIC_UUID]]){
        [self setBleTagData:characteristic];
    }
}


//////////////////////////////////////////////////////
- (void) setHeartBPMData: (CBCharacteristic *) characteristic
                   error:(NSError *) error
{
    // Get the Heart Rate Monitor BPM
    NSData *data = [characteristic value];      // 1
    const uint8_t *reportData = [data bytes];
    uint16_t bpm = 0;
    
    if ((reportData[0] & 0x01) == 0) {          // 2
        // Retrieve the BPM value for the Heart Rate Monitor
        bpm = reportData[1];
    }
    else {
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));  // 3
    }
    // Display the heart rate value to the UI if no error occurred
    if( (characteristic.value)  || !error ) {   // 4
        hr = [NSString stringWithFormat:@"%i",bpm];
        NSLog(@"%i",bpm);
        // self.heartRateBPM.text = [NSString stringWithFormat:@"%i bpm", bpm];
        // self.heartRateBPM.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:28];
    }
    return;
}


- (void) setManufacturerName:(CBCharacteristic *) characteristic
{
    // NSString *manufacturerName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];  // 1
    // self.manufacturer = [NSString stringWithFormat:@"Manufacturer: %@", manufacturerName];    // 2
    return;
}


- (void) setBodyLocation:(CBCharacteristic *)characteristic
{
//    NSData *sensorData = [characteristic value];         // 1
//    uint8_t *bodyData = (uint8_t *)[sensorData bytes];
//    if (bodyData ) {
//        uint8_t bodyLocation = bodyData[0];  // 2
//        // self.bodyData = [NSString stringWithFormat:@"Body Location: %@", bodyLocation == 1 ? @"Chest" : @"Undefined"]; // 3
//    }
//    else {  // 4
//        // self.bodyData = [NSString stringWithFormat:@"Body Location: N/A"];
//    }
    return;
}

- (void) setBleTagData:(CBCharacteristic *)characteristic
{
    
    NSData   * data = characteristic.value;
    NSString * str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    bleTagRawData = str;
    if (str != nil) {
        bleTagRawData = str;
    }else{
        bleTagRawData = @"";
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SENBAY_EVENT_BLETAG_DID_RECEIVED_DATA object:bleTagRawData];
    
    /**
     * BLEでは，UDP的に通信を行うため，パケットが後から届く可能性がある．
     * 時間差の影響を無くすために，「時間」データだけを取り出して，前回の「時間」データより新しければデータに追加する．
     */
    //NSString
    // NSString* decodedStr = [comp decode:str baseNumber:baseNumber];
    // NSLog(@"%@",decodedStr);
    // NSArray* sensorDataElements = [decodedStr componentsSeparatedByString:@","];
    //        NSLog(@"----> %d", [sensorDataElements count]);
    //        if([sensorDataElements count] > 1){
    //            NSArray* timeElement = [[sensorDataElements objectAtIndex:1] componentsSeparatedByString:@":"];
    //            if([timeElement count] > 0 ){
    //                double latestUpdateTimeOfBLE = [[timeElement objectAtIndex:1] doubleValue];
    //                if(lastUpdateTimeOfBLE < latestUpdateTimeOfBLE){
    //                    self.sensorDataLine = [str copy];
    //                }else{
    //                    NSLog(@"error");
    //                }
    //                NSLog(@"%f < %f", lastUpdateTimeOfBLE, latestUpdateTimeOfBLE);
    //                lastUpdateTimeOfBLE = latestUpdateTimeOfBLE;
    //            }
    //        }
    //sensorDataLine = str;
    //}
    //    NSArray *acc = [str componentsSeparatedByString:@","];
    //    NSLog(@"%ld",[acc count]);
    //    NSLog(@"%@", [comp decode:str baseNumber:121]);
}

@end

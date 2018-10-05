# SenbayKit

[![CI Status](https://img.shields.io/travis/tetujin/SenbayKit.svg?style=flat)](https://travis-ci.org/tetujin/SenbayKit)
[![Version](https://img.shields.io/cocoapods/v/SenbayKit.svg?style=flat)](https://cocoapods.org/pods/SenbayKit)
[![License](https://img.shields.io/cocoapods/l/SenbayKit.svg?style=flat)](https://cocoapods.org/pods/SenbayKit)
[![Platform](https://img.shields.io/cocoapods/p/SenbayKit.svg?style=flat)](https://cocoapods.org/pods/SenbayKit)

SenbayKit is a development library for adding Senbay functions to your iOS app. In this library, three core libraries are included: Senbay Camera, Player, and Reader.

<p align="center">
    <img src="Media/senbay_promotion.gif", width="480">
</p>


## Requirements
SenbayKit requires iOS10 or later

## Example
To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation
SenbayKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SenbayKit', :git => 'https://github.com/tetujin/SenbayKit.git'
```

## How to use

###  Settings
1. Setup Info.plist
Please add following keys to Info.plist
- NSCameraUsageDescription
- NSMicrophoneUsageDescription
- NSPhotoLibraryUsageDescription
- NSLocationWhenInUseUsageDescription (only for SenbayCamera)

2. Import SenbayKit into your source code
```
@import SenbayKit;
```

### Senbay Camera
1. Initialize SenbayCamera and set a preview view
```
SenbayCamera * camera = [[SenbayCamera alloc] initWithPreviewView:UI_IMAGE_VIEW];
camera.delegate = self;
[camera activate];
```

2. Fix a UIViewController orientation
SenbayCamera supports only LandscapeRigth. Please add following code to your UIViewController for fixing the UIViewController. 
```
- (BOOL) shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
```

3. Start and stop a video recording process
The recorded video is saved into Photos.app automatically.
```
/// start ///
[camera startRecording];

/// stop ///
[camera stopRecording];
```

<p align="center">
    <img src="Media/sample_senbay_video.gif", width="480">
</p>

4. Activate sensors
You can embedded sensor data into an animated QR code on a video. Please activate required sensors from SenbaySensorManager class.
```
// Accelerometer: ACCX,ACCY,ACCZ
[camera.sensorManager.imu activateAccelerometer];
// Gyroscope:     PITC,ROLL,YAW
[camera.sensorManager.imu activateGyroscope];
// Magnetometer:  MAGX,MAGY,MAGZ
[camera.sensorManager.imu activateMagnetometer];

// GPS:               LONG,LATI,ALTI
[camera.sensorManager.location activateGPS];
// Compass:           HEAD
[camera.sensorManager.location activateCompass];
// Barometer:         AIRP
[camera.sensorManager.location activateBarometer];
// Speedometer:       SPEE
[camera.sensorManager.location activateSpeedometer];

// Motion Activity:   MACT
[camera.sensorManager.motionActivity activate];

// Battery:           BATT
[camera.sensorManager.batteryLevel activate];
// Screen Brightness: BRIG
[camera.sensorManager.screenBrightness activate];

// Weather:           TEMP,WEAT,HUMI,WIND
[camera.sensorManager.weather activate];

// HR:                HTBT
[camera.sensorManager.ble activateHRM];
// BLE Tag:           BTAG
[camera.sensorManager.ble activateBLETag];
// Network Socket:    NTAG
[camera.sensorManager.networkSocket activateUdpScoketWithPort:5000];
```

If you want to use your original data format, please call -useFreeFormatData:, and set your data to the SenbaySensorManager.
```
[camera.sensorManager useFreeFormatData:YES];
[camera.sensorManager setFreeFormatData:@"YOUR DATA"];
```

5. Implement SenbayCameraDelegate on UIViewController
You can receive update events from SenbayCamera via SenbayCameraDelegate.
```
- (void) didUpdateFormattedRecordTime:(NSString *)recordTime;
- (void) didUpdateCurrentFPS:(int)currentFPS;
- (void) didUpdateQRCodeContent:(NSString *)qrcodeContent;
- (void) didUpdateVideoFrame:(UIImage *)videoFrame;
```

### Senbay Player
1. Initialize SenbayPlayer on UIViewController
```
SenbayPlaer * player = [[SenbayPlayer alloc] initWithView:UI_VIEW];
player.delegate = self;
[player setupPlayerWithLoadedAsset:ASSET];
```

2. Play and stop the SenbayPlayer 
```
// play
[player.player play];
// pause
[player.player pause];
```

3. Implement SenbayPlayerDelegate on UIViewController
You can receive the decoded sensor data by implementing the delegate.
```
- (void)didDetectQRcode:(NSString *)qrcode;
- (void)didDecodeQRcode:(NSDictionary *)senbayData;
```

### Senbay Reader
1.  Initialize SenbayReader on UIViewController
```
SenbayReader * reader = [[SenbayReader alloc] init];
reader.delegate = self;
[reader startCameraReaderWithPreviewView:UI_VIEW];
```

2. Receive detected and decoded data via SenbayReaderDelegate 
```
- (void)didDetectQRcode:(NSString *)qrcode;
- (void)didDecodeQRcode:(NSDictionary *)senbayDat;
```

## Author and Contributors

SenbayKit is authord by [Yuuki Nishiyama](http://www.yuukinishiyama.com). In addition, [Takuro Yonezawa](https://www.ht.sfc.keio.ac.jp/~takuro/), [Denzil Ferreira](http://www.oulu.fi/university/researcher/denzil-ferreira), [Anind K. Dey](http://www.cs.cmu.edu/~anind/), [Jin Nakazawa](https://keio.pure.elsevier.com/ja/persons/jin-nakazawa) are deeply contributing this project. Please see more detail information on our [website](http://www.senbay.info).

## Related Links
* [Senbay Platform Offical Website](http://www.senbay.info)
* [Senbay YouTube Channel](https://www.youtube.com/channel/UCbnQUEc3KpE1M9auxwMh2dA/videos)

## Citation
Please cite these papers in your publications if it helps your research:

```
@inproceedings{Nishiyama:2018:SPI:3236112.3236154,
    author = {Nishiyama, Yuuki and Dey, Anind K. and Ferreira, Denzil and Yonezawa, Takuro and Nakazawa, Jin},
    title = {Senbay: A Platform for Instantly Capturing, Integrating, and Restreaming of Synchronized Multiple Sensor-data Stream},
    booktitle = {Proceedings of the 20th International Conference on Human-Computer Interaction with Mobile Devices and Services Adjunct},
    series = {MobileHCI '18},
    year = {2018},
    location = {Barcelona, Spain},
    publisher = {ACM},
} 
```

## License

SenbayKit is available under the Apache License, Version 2.0 license. See the LICENSE file for more info.

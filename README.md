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
SenbayKit requires iOS10 or later. This library supports both **Swift** and **Objective-C**.

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
```objc
// Objective-C //
SenbayCamera * camera = [[SenbayCamera alloc] initWithPreviewView: UI_IMAGE_VIEW];
camera.delegate = self;
[camera activate];
```
```swift
// Swift //
var camera = SenbayCamera.init(previewView: UI_IMAGE_VIEW)
camera.delegate = self;
camera.activate()
```

2. Fix a UIViewController orientation
SenbayCamera supports only LandscapeRigth. Please add following code to your UIViewController for fixing the UIViewController. 
```objc
// Objective-C //
- (BOOL) shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}
```
```swift
// Swift //
override var shouldAutorotate: Bool {
    return  false
}

override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
    return .landscapeRight
}

```

3. Start and stop a video recording process
The recorded video is saved into Photos.app automatically.
```objc
// Objective-C //
[camera startRecording];
[camera stopRecording];
```
```swift
// Swift //
camera.startRecording()
camera.stopRecording()
```
<p align="center">
    <img src="Media/sample_senbay_video.gif", width="480">
</p>

4. Activate sensors
You can embedded sensor data into an animated QR code on a video. Please activate required sensors from SenbaySensorManager class.
```objc
// Objective-C //
// Accelerometer: ACCX,ACCY,ACCZ
[camera.sensorManager.imu activateAccelerometer];
// Gyroscope:     PITC,ROLL,YAW
[camera.sensorManager.imu activateGyroscope];
// Magnetometer:  MAGX,MAGY,MAGZ
[camera.sensorManager.imu activateMagnetometer];

// GPS:         LONG,LATI,ALTI
[camera.sensorManager.location activateGPS];
// Compass:     HEAD
[camera.sensorManager.location activateCompass];
// Barometer:   AIRP
[camera.sensorManager.location activateBarometer];
// Speedometer: SPEE
[camera.sensorManager.location activateSpeedometer];

// Motion Activity:   MACT
[camera.sensorManager.motionActivity activate];

// Battery:           BATT
[camera.sensorManager.batteryLevel activate];
// Screen Brightness: BRIG
[camera.sensorManager.screenBrightness activate];

// Weather:        TEMP,WEAT,HUMI,WIND
[camera.sensorManager.weather activate];

// HR:             HTBT
[camera.sensorManager.ble activateHRM];
// BLE Tag:        BTAG
[camera.sensorManager.ble activateBLETag];
// Network Socket: NTAG
[camera.sensorManager.networkSocket activateUdpScoketWithPort:5000];
```
```swift
// Swift //
// Accelerometer: ACCX,ACCY,ACCZ
if let imu = camera.sensorManager.imu{
    imu.activateAccelerometer()
}

// GPS: LONG,LATI,ALTI
if let location = camera.sensorManager.location {
    location.activateGPS()
}

// Weather: TEMP,WEAT,HUMI,WIND
if let weather = camera.sensorManager.weather{
    weather.activate()
}
```

If you want to use your original data format, please call -useFreeFormatData:, and set your data to the SenbaySensorManager.
```objc
// Objective-C //
[camera.sensorManager useFreeFormatData:YES];
[camera.sensorManager setFreeFormatData:@"YOUR DATA"];
```
```swift
// Swift //
camera.sensorManager.useFreeFormatData(true)
camera.sensorManager.setFreeFormatData("YOUR DATA")
```

5. Implement SenbayCameraDelegate on UIViewController
You can receive update events from SenbayCamera via SenbayCameraDelegate.
```objc
// Objective-C //
- (void) didUpdateFormattedRecordTime:(NSString *)recordTime;
- (void) didUpdateCurrentFPS:(int)currentFPS;
- (void) didUpdateQRCodeContent:(NSString *)qrcodeContent;
- (void) didUpdateVideoFrame:(UIImage *)videoFrame;
```
```swift
// Swift //
func didUpdateCurrentFPS(_ currentFPS: Int32)
func didUpdateFormattedRecordTime(_ recordTime: String!)
func didUpdateQRCodeContent(_ qrcodeContent: String!)
func didUpdateVideoFrame(_ videoFrame: UIImage!)
```

6. (Option) Live Stream SenbayVideo via RTMP
RTMP (Real-Time Messaging Protocol) is one of a video, audio, and data streaming protocoal which is suppored on YouTube Live. 
You can stream SenbayVideo if you want via RTMP on SenbayKit.

```objc
/// start a broadcast via YouTube Live (Please relace [xxxx-xxxx-xxxx-xxxx] to your stream name. You can get the name from https://www.youtube.com/live_dashboard )
[camera startBroadcastWithStreamName:@"[xxxx-xxxx-xxxx-xxxx]" 
                         endpointURL:@"rtmp://username:[xxxx-xxxx-xxxx-xxxx]@a.rtmp.youtube.com/live2"];
                         
/// stop the broadcast
[camera finishBroadcast];
```

```swift
/// start a broadcast
camera.startBroadcast(withStreamName:"[xxxx-xxxx-xxxx-xxxx]",
                         endpointURL:"rtmp://username:[xxxx-xxxx-xxxx-xxxx]@a.rtmp.youtube.com/live2")
                         
/// stop the broadcast
camera.finishBroadcast()
```

7. (Option) Change camera settings
You can cahnge camera settings (e.g., FPS, resolution, video export) using `SenbayCameraConfig` class on `SenbayCamera` before execute `-activate` method.

```objc
/// orverwride SenbayCameraConfig
SenbayCameraConfig * cameraConfig = [[SenbayCameraConfig alloc] initWithBuilderBlock:^(SenbayCameraConfig * _Nonnull config) {
  config.maxFPS = 30;
  config.videoSize = AVCaptureSessionPreset1280x720;
  config.isDebug = YES;
}];
camera.config = cameraConfig;

/// or edit SenbayCameraConfig directly 
camera.config.maxFPS = 60;

/// NOTE: The settings should be modified before activate the camera instance
[camera activate];
```

```swift
let config = SenbayCameraConfig.init { (config) in
  config.isDebug = true
  config.maxFPS = 30
  config.videoSize = AVCaptureSession.Preset.hd1280x720
}
camera.config = cameraConfig;

/// or edit SenbayCameraConfig directly 
camera.config.maxFPS = 60;

/// NOTE: The settings should be modified before activate the camera instance
camera.activate();
```

### Senbay Player
1. Initialize SenbayPlayer on UIViewController
```objc
// Objective-C //
SenbayPlaer * player = [[SenbayPlayer alloc] initWithView:UI_VIEW];
player.delegate = self;
[player setupPlayerWithLoadedAsset: ASSET];
```
```swift
// Swift //
player = SenbayPlayer.init(view: playerView)
player.delegate = self;
player.setupPlayer(withLoadedAsset: ASSET)
```

2. Play and pause the SenbayPlayer 
```objc
// Objective-C //
[player play];
[player pause];
```
```swift
// Swift //
player.play()
player.pause()
```

3. Implement SenbayPlayerDelegate on UIViewController
You can receive the decoded sensor data by implementing the delegate.
```objc
// Objective-C //
- (void)didDetectQRcode:(NSString *)qrcode;
- (void)didDecodeQRcode:(NSDictionary *)senbayData;
```
```swift
// Swift //
func didDetectQRcode(_ qrcode: String!)
func didDecodeQRcode(_ senbayData: [AnyHashable : Any]!)
```

### Senbay Reader
1.  Initialize SenbayReader on UIViewController
```objc
// Objective-C //
SenbayReader * reader = [[SenbayReader alloc] init];
reader.delegate = self;
[reader startCameraReaderWithPreviewView: UI_VIEW];
```
```swift
// Swift //
var reader = SenbayReader()
reader.delegate = self;
reader.startCameraReader(withPreviewView: UI_VIEW)
```

2. Receive detected and decoded data via SenbayReaderDelegate 
```objc
// Objective-C //
- (void)didDetectQRcode:(NSString *)qrcode;
- (void)didDecodeQRcode:(NSDictionary *)senbayDat;
```
```swift
// Swift //
func didDetectQRcode(_ qrcode: String!)
func didDecodeQRcode(_ senbayData: [AnyHashable : Any]!)
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

//
//  SenbayCameraViewController.m
//  SenbayKit_Example
//
//  Created by Yuuki Nishiyama on 2018/10/03.
//  Copyright © 2018 tetujin. All rights reserved.
//

#import "SenbayCameraViewController.h"

@interface SenbayCameraViewController ()

@end

@implementation SenbayCameraViewController{
    SenbayCamera * camera;
    bool isRecording;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    SenbayCameraConfig * cameraConfig = [[SenbayCameraConfig alloc] initWithBuilderBlock:^(SenbayCameraConfig * _Nonnull config) {
        config.maxFPS = 30;
        config.videoSize = AVCaptureSessionPreset1280x720;
        config.isCamouflageQRCode    = YES;
        config.isExportOriginalVideo = YES;
        config.isExportSenbayVideo   = YES;
        config.isDebug = YES;
    }];
    
    camera = [[SenbayCamera alloc] initWithPreviewView:_previewImageView config:cameraConfig];
    camera.config = cameraConfig;
    camera.delegate = self;
    
    [camera activate];
    
    // Accelerometer:     ACCX,ACCY,ACCZ
    [camera.sensorManager.imu      activateAccelerometer];
//    // Gyroscope:         PITC,ROLL,YAW
//    [camera.sensorManager.imu      activateGyroscope];
//    // Magnetometer:      MAGX,MAGY,MAGZ
//    [camera.sensorManager.imu      activateMagnetometer];
    // GPS:               LONG,LATI,ALTI
    [camera.sensorManager.location activateGPS];
//    // Compass:           HEAD
//    [camera.sensorManager.location activateCompass];
//    // Barometer:         AIRP
    [camera.sensorManager.location activateBarometer];
//    // Speedometer:       SPEE
//    [camera.sensorManager.location activateSpeedometer];
//    // Motion Activity:   MACT
//    [camera.sensorManager.motionActivity activate];
//    // Battery:           BATT
//    [camera.sensorManager.batteryLevel   activate];
//    // Screen Brightness: BRIG
//    [camera.sensorManager.screenBrightness activate];
//    // Weather:           TEMP,WEAT,HUMI,WIND
    [camera.sensorManager.weather activate];
//    // HR:                HTBT
//    [camera.sensorManager.ble     activateHRM];
//    // BLE Tag:           BTAG
//    [camera.sensorManager.ble     activateBLETag];
//    // Network Socket:    NTAG
//    [camera.sensorManager.networkSocket activateUdpScoketWithPort:5000];
}

- (IBAction)pushedCaptureButton:(UIButton *)sender {
    if (isRecording) {
        [camera stopRecording];
        isRecording = NO;
        [_captureButton setTitle:@"Start" forState:UIControlStateNormal];
        
//        [camera startBroadcastWithStreamName:@"" endpointURL:@""];
        
    }else{
        [camera startRecording];
        isRecording = YES;
        [_captureButton setTitle:@"Stop" forState:UIControlStateNormal];
    
//        [camera finishBroadcast];
    }
}


- (IBAction)pushedCloseButton:(UIButton *)sender {
    if (isRecording) {
        [self pushedCaptureButton:sender];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didUpdateFormattedRecordTime:(NSString *)recordTime{
    if (recordTime != nil) {
        _timeLabel.text = recordTime;
    }
}

- (void)didUpdateCurrentFPS:(int)currentFPS{
    // NSLog(@"%d", currentFPS);
    _fpsLabel.text = [NSString stringWithFormat:@"%d FPS", currentFPS];
}

- (void)didUpdateQRCodeContent:(NSString *)qrcodeContent{
    // NSLog(@"%@", qrcodeContent);
    _rawDataLabel.text = qrcodeContent;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL) shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}


@end

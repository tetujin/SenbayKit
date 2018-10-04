//
//  CoreSenbay.h
//
//  Created by Yuuki Nishiyama on 2018/06/27.
//  Copyright © 2018 Yuuki Nishiyama. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import <Photos/PHPhotoLibrary.h>
#import <Photos/PHAssetChangeRequest.h>
#import <CoreMedia/CoreMedia.h>

#import "SenbaySensorManager.h"

@protocol SenbayCameraDelegate <NSObject>
@optional
- (void) didUpdateFormattedRecordTime :(NSString *) recordTime;
- (void) didUpdateCurrentFPS:(int) currentFPS;
- (void) didUpdateQRCodeContent:(NSString *)qrcodeContent;
- (void) didUpdateVideoFrame:(UIImage *)videoFrame;
@end

@interface SenbayCamera : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>{
    AVAssetWriter *senbayAssetWriter;
    AVCaptureVideoDataOutput * videoDataOutput;
    AVCaptureAudioDataOutput * audioDataOutput;
    AVAssetWriterInput * videoInput;
    AVAssetWriterInput * audioInput;
    
    int qrBGColorRed;
    int qrBGColorGreen;
    int qrBGColorBlue;
    // int qrBGColorAlpha;
    
    int qrBLKColorRed;
    int qrBLKColorGreen;
    int qrBLKColorBlue;
    // int qrBKLColorAlpha;
    
    UIImage     * qrCode;
    UIImage     * qrCodeLayer;
}

// typedef void (^UIElementUpdateCompletionHundler)(void);

@property (weak, nonatomic) id <SenbayCameraDelegate> delegate;

- (instancetype)initWithPreviewView:(UIImageView *) previewView;
- (bool) activate;
- (bool) deactivate;
- (void) setQRCodeContent:(NSString *) content;
- (UIImage *) getQRCodeFilterLayer;

@property (readonly) AVCaptureSession * captureSession;
@property (readonly) AVCaptureDevice  * camera;
@property (readonly) AVCaptureVideoPreviewLayer *previewLayer;
// @property (readonly) UIImageView           * qrcodeView;
// @property UIView        * cameraPreviewView;
@property UIImageView        * basePreviewView;
@property NSURL     * videoFileURL;

// camera settings
@property AVFileType              videoFileType;
@property AVCaptureSessionPreset  videoSize;
@property AVCaptureDevicePosition cameraPosition;
@property UIInterfaceOrientation  cameraOrientation;
@property AVVideoCodecType        videoCodec;
@property int    maxFPS;

// QR code setting
@property int    qrCodeSize;
@property int    qrCodeX;
@property int    qrCodeY;

@property BOOL   isCamouflageQRCodeAutomatically;
@property double camouflageInterval;
@property int    camouflageColorDiff; // 0 - 255 //

- (void) setQRCodeBackgroundColor:(UIColor *)color;
- (void) setQRCodeBlockColor:(UIColor *)color;
- (void) setQRCodeBackgroundColorWithRead:(int)r green:(int)g blue:(int)b;
- (void) setQRCodeBlockColorWithRead:(int)r green:(int)g blue:(int)b;

// status
@property (readonly) BOOL       isRecording;
@property (readonly) NSString * formattedTime;
@property BOOL isDebug;

// video controller
- (void) startRecording;
- (void) stopRecording;

// sensor
@property (readonly) SenbaySensorManager * sensorManager;


@end

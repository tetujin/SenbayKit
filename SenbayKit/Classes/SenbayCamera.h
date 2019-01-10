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
#import "SenbayCameraConfig.h"
#import "SenbayQRcode.h"

@protocol SenbayCameraDelegate <NSObject>
@optional
- (void) didUpdateFormattedRecordTime :(NSString *) recordTime;
- (void) didUpdateCurrentFPS:(int) currentFPS;
- (void) didUpdateQRCodeContent:(NSString *)qrcodeContent;
- (void) didUpdateVideoFrame:(UIImage *)videoFrame;
- (void) senbayCaptureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
@end

@interface SenbayCamera : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>{
    
    AVCaptureVideoDataOutput * videoDataOutput;
    AVCaptureAudioDataOutput * audioDataOutput;
    
    AVAssetWriter *senbayAssetWriter;
    AVAssetWriterInput * senbayVideoInput;
    AVAssetWriterInput * senbayAudioInput;
    
    AVAssetWriter *originalAssetWriter;
    AVAssetWriterInput * originalVideoInput;
    AVAssetWriterInput * originalAudioInput;
    
    UIImage     * qrcodeIamge;
    UIImage     * qrcodeLayer;
}

@property (weak, nonatomic) id <SenbayCameraDelegate> delegate;

@property (nonnull) SenbayCameraConfig * config;

@property (nonnull, readonly) SenbayQRcode * qrcode;

// status
@property (readonly) BOOL       isRecording;
@property (readonly) NSString * formattedTime;

// sensor
@property (readonly) SenbaySensorManager * sensorManager;

// camera related instances
@property (readonly) AVCaptureSession * captureSession;
@property (readonly) AVCaptureDevice  * camera;
@property (readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property UIImageView        * basePreviewView;


- (instancetype)initWithPreviewView:(UIImageView *) previewView;
- (instancetype)initWithPreviewView:(UIImageView *) previewView config:(SenbayCameraConfig *)config;

// camera controller
- (bool) activate;
- (bool) deactivate;

- (void) setQRCodeContent:(NSString *) content;
- (UIImage *) getQRCodeFilterLayer;

// video controller
- (void) startRecording;
- (void) stopRecording;

// boradcast
- (void) startBroadcastWithStreamName:(NSString*)streamName endpointURL:(NSString *)endpointURL;
- (void) finishBroadcast;
- (void) pouseBroadcast;
- (void) resumeBroadcast;



@end

//
//  SenbayCameraConfig.h
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2019/01/10.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SenbayCameraConfig : NSObject

- (instancetype) initWithBuilderBlock:(void(^)(SenbayCameraConfig *config))builderBlock;

@property BOOL isDebug;

@property (nonnull) NSURL     * senbayVideoFileURL;
@property (nonnull) NSURL     * originalVideoFileURL;

// camera settings
@property (nonnull) AVFileType              videoFileType;
@property (nonnull) AVCaptureSessionPreset  videoSize;
@property AVCaptureDevicePosition cameraPosition;
@property UIInterfaceOrientation  cameraOrientation;
@property (nonnull) AVVideoCodecType        videoCodec;
@property int    maxFPS;
@property int    minFPS;

@property double camouflageInterval;

@property BOOL   isExportSenbayVideo;
@property BOOL   isExportOriginalVideo;
@property BOOL   isCamouflageQRCode;

// QR code setting
@property int    qrcodeSize;
@property int    qrcodePositionX;
@property int    qrcodePositionY;

@end

NS_ASSUME_NONNULL_END

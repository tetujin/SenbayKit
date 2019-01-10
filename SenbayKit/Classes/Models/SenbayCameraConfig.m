//
//  SenbayCameraConfig.m
//  CocoaAsyncSocket
//
//  Created by Yuuki Nishiyama on 2019/01/10.
//

#import "SenbayCameraConfig.h"

@implementation SenbayCameraConfig

- (instancetype)init{
    self = [super init];
    if(self != nil){
        _videoCodec        = AVVideoCodecH264;
        _videoFileType     = AVFileTypeQuickTimeMovie;
        _maxFPS            = 60;                                     // 60FPS
        _minFPS            = 30;                                     // 30FPS
        _videoSize         = AVCaptureSessionPreset1280x720;         // 1280x720
        _cameraPosition    = AVCaptureDevicePositionBack;            // back camera
        _cameraOrientation = UIInterfaceOrientationLandscapeRight;   // landscape
        
        // init a URL for video file
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _senbayVideoFileURL   = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"senbay_video.mov"]];
        _originalVideoFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"original_video.mov"]];
        
        _camouflageInterval  =   5;
        _isCamouflageQRCode = NO;
        _isExportSenbayVideo = YES;
        _isExportOriginalVideo = NO;
        
        _isDebug = NO;
        
        _qrcodeSize = 1280 * 0.15;
        _qrcodePositionX = 0;
        _qrcodePositionY = 0;
    }
    return self;
}

- (instancetype) initWithBuilderBlock:(void(^)(SenbayCameraConfig *config))builderBlock{
    self = [self init];
    if (self != nil){
        builderBlock(self);
    }
    return self;
}


@end

//
//  CoreSenbay.m
//
//  Created by Yuuki Nishiyama on 2018/06/27.
//  Copyright © 2018 Yuuki Nishiyama. All rights reserved.
//

#import "SenbayCamera.h"
#import "SenbayData.h"
#import <MobileCoreServices/UTCoreTypes.h>

#import <SenbayKit/SenbayKit-Swift.h>

@implementation SenbayCamera
{
    // Local photo library instance
    PHPhotoLibrary * library;

    // Video writer for senbay video
    AVAssetWriter * videoWriter;
    
    // Main clock timer
    NSTimer   * mainTimer;
    NSDate    * startTime;

    // Camouflage timer;
    NSTimer * camouflageTimer;
    BOOL camouflageFlag;
    
    bool haveStartedSession;
    
    dispatch_queue_t cameraProcessingQueue, audioProcessingQueue;

    float videoWidth;
    float videoHeight;
    
    EAGLContext * eaglContext;
    CIContext   * eaglCIContext;
    
    CIContext * previewCIContext;
    
    CIContext * camouflageContext;
    
    int threadSyncStack;
    int qrCodeGenStack;
    int previewSyncStack;
    int previewImgGenStack;
    
    double fpsStartTime;
    int fpsCurrentFrames;
    
    RTMPHandler * rtmpHandler;
    bool isBroadcast;
}

@synthesize basePreviewView = _basePreviewView;

- (instancetype) init
{
    return [self initWithPreviewView:nil];
}

- (instancetype)initWithPreviewView:(UIImageView *) previewView{
    return [self initWithPreviewView:previewView config:nil];
}

- (instancetype)initWithPreviewView:(UIImageView *) previewView config:(SenbayCameraConfig *)config
{
    self = [super init];
    if (self) {
        
        _qrcode = [[SenbayQRcode alloc] init];
        
        if (config == nil) {
            _config = [[SenbayCameraConfig alloc] init];
        }else{
            _config = config;
        }
        
        // set preview view
        _basePreviewView  = previewView;
        
        previewCIContext  = [CIContext contextWithOptions:nil];
        camouflageContext = [CIContext contextWithOptions:nil];

        library       = [PHPhotoLibrary sharedPhotoLibrary];
        
        // init camera settings
        _isRecording       = NO;
        
        threadSyncStack    = 0;
        qrCodeGenStack     = 0;
        previewSyncStack   = 0;
        previewImgGenStack = 0;
        
        videoWidth         = 1280;
        videoHeight        = 720;
        
        cameraProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        audioProcessingQueue  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,  0);
        
        eaglContext   = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        eaglCIContext = [CIContext contextWithEAGLContext:eaglContext
                                                                options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
        [self setQRCodeContent:@""];
        
        _sensorManager = [[SenbaySensorManager alloc] init];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onOrientationChanged:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        
        rtmpHandler = [[RTMPHandler alloc] init];
        isBroadcast = false;
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (bool) activate
{
    // start preview
    return [self initCamera];
}

- (bool) deactivate
{
    // stop preview
    return YES;
}

- (bool) initCamera{
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:_config.senbayVideoFileURL error:&error];
    if (error!=nil) {
        if (_config.isDebug) NSLog(@"[SenbayCamera] %@", error.debugDescription);
    }
    
    error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:_config.originalVideoFileURL error:&error];
    if (error!=nil) {
        if (_config.isDebug) NSLog(@"[SenbayCamera] %@", error.debugDescription);
    }
    
    ///////////////////////////////////
    // (1) Setup camera input
    NSError * cameraInitError = nil;
    
    _camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *cameraDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:_camera error:&cameraInitError];
    
    /////////////////////////////////////
    // (2) Setup microphone
    NSError * micInitError = nil;
    AVCaptureDevice      * microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput * micDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:microphone error:&micInitError];
    
    ////////////////////////////////////////
    // (6) Setup video&audio output
    NSDictionary* settings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    // NSDictionary* settings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]};
    videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoDataOutput.videoSettings = settings;
    [videoDataOutput setSampleBufferDelegate:self queue:cameraProcessingQueue];
    
    audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioDataOutput setSampleBufferDelegate:self queue:audioProcessingQueue];
    
    //////////////////////////////////
    _captureSession = [[AVCaptureSession alloc] init];

    _captureSession.sessionPreset = _config.videoSize;
    
    [_captureSession addInput:cameraDeviceInput];
    [_captureSession addOutput:videoDataOutput];
    [_captureSession addInput:micDeviceInput];
    [_captureSession addOutput:audioDataOutput];
    
    
    if(_config.videoSize == AVCaptureSessionPreset3840x2160){
        videoWidth = 3840;
        videoHeight = 2160;
    }else if(_config.videoSize == AVCaptureSessionPreset1920x1080){
        videoWidth = 1920;
        videoHeight = 1080;
    }else if(_config.videoSize == AVCaptureSessionPreset1280x720){
        videoWidth = 1280;
        videoHeight = 720;
    }else if(_config.videoSize == AVCaptureSessionPreset640x480){
        videoWidth = 640;
        videoHeight = 480;
    }
    
    NSDictionary *outputSettings  = [NSDictionary dictionaryWithObjectsAndKeys:
                                      AVVideoCodecH264, AVVideoCodecKey, //1920x1080
                                      [NSNumber numberWithInt:videoWidth],  AVVideoWidthKey,
                                      [NSNumber numberWithInt:videoHeight], AVVideoHeightKey,
                                     nil ];
    // senbay video asset
    NSError * assetWriterError = nil;
    senbayAssetWriter = [[AVAssetWriter alloc] initWithURL:_config.senbayVideoFileURL
                                                  fileType:_config.videoFileType
                                                     error:&assetWriterError];
    senbayVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    senbayVideoInput.expectsMediaDataInRealTime = YES;
    senbayAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil];
    senbayAudioInput.expectsMediaDataInRealTime = YES;
    [senbayAssetWriter  addInput:senbayVideoInput];
    [senbayAssetWriter  addInput:senbayAudioInput];
    
    // original video asset
    NSError * originalAssetWriterError = nil;
    originalAssetWriter = [[AVAssetWriter alloc] initWithURL:_config.originalVideoFileURL
                                                  fileType:_config.videoFileType
                                                     error:&originalAssetWriterError];
    originalVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    originalVideoInput.expectsMediaDataInRealTime = YES;
    originalAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil];
    originalAudioInput.expectsMediaDataInRealTime = YES;
    [originalAssetWriter  addInput:originalVideoInput];
    [originalAssetWriter  addInput:originalAudioInput];
    
    // set video orientation
    [_captureSession beginConfiguration];
    for ( AVCaptureConnection *connection in [videoDataOutput connections] ) {
        if ([connection isVideoOrientationSupported]) {
            [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
            // connection.videoOrientation = videoOrientationFromDeviceOrientation([UIDevice currentDevice].orientation);
        }
    }
    [_captureSession commitConfiguration];
    
    [self configureCameraForHighestFrameRate:_camera size:_config.videoSize maxFPS:_config.maxFPS];

    // set FPS
    NSError *deviceConfigError;
    [_camera lockForConfiguration:&deviceConfigError];
    if (deviceConfigError == nil) {
        if (_camera.activeFormat.videoSupportedFrameRateRanges){
            [_camera setActiveVideoMinFrameDuration:CMTimeMake(1, _config.minFPS)];
            [_camera setActiveVideoMaxFrameDuration:CMTimeMake(1, _config.maxFPS)];
        }
    }
    [_camera unlockForConfiguration];
    
    if (_config.isCamouflageQRCode){
        if(camouflageTimer != nil){
            [camouflageTimer invalidate];
            camouflageTimer = nil;
        }
        if (_config.isDebug) {
            NSLog(@"[SenbayCamera] Camouflage Interval   = %f second", _config.camouflageInterval);
        }
        [NSTimer scheduledTimerWithTimeInterval:_config.camouflageInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
            self->camouflageFlag = YES;
        }];
    }
    
    // Start recording
    [_captureSession startRunning];
    
    return YES;
}

- (void) startBroadcastWithStreamName:(NSString *)streamName endpointURL:(NSString *)endpointURL{
    [rtmpHandler broadcastStartedWithSetupInfo:@{@"endpointURL":endpointURL,
                                                 @"streamName":streamName}];
    isBroadcast = YES;
}

- (void) finishBroadcast {
    [rtmpHandler broadcastFinished];
    isBroadcast = NO;
}

- (void) pouseBroadcast{
    [rtmpHandler broadcastPaused];
    isBroadcast = NO;
}

- (void) resumeBroadcast{
    [rtmpHandler broadcastResumed];
    isBroadcast = YES;
}

- (void) onOrientationChanged:(id)sender {
//    if (!_isRecording) {
//        NSLog(@"[SenbayCamera] rotate the camera imput");
//        if (_captureSession != nil && videoDataOutput !=nil) {
//            [_captureSession beginConfiguration];
//            for ( AVCaptureConnection *connection in [videoDataOutput connections] ) {
//                if ([connection isVideoOrientationSupported]) {
//                    connection.videoOrientation = videoOrientationFromDeviceOrientation([UIDevice currentDevice].orientation);
//                }
//            }
//            [_captureSession commitConfiguration];
//        }
//    }else{
//        NSLog(@"[SenbayCamera] cannot rotate camera input");
//    }
}


- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // Measuring FPS
    if (output == videoDataOutput) {
        fpsCurrentFrames++;
        double now = [NSDate new].timeIntervalSince1970;
        if(fpsStartTime==0){
            fpsStartTime = now;
        }else if(fpsStartTime+1 < now ){
            int tempFPS = fpsCurrentFrames;
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(didUpdateCurrentFPS:)]) {
                    [self.delegate didUpdateCurrentFPS:tempFPS];
                }
            });
            fpsCurrentFrames = 0;
            fpsStartTime = now;
        }
    }
    
    if( !CMSampleBufferDataIsReady(sampleBuffer) ){
        return;
    }
   
    // just make a simple preview image and set it to the preview view
    if (!_isRecording){
        if (output == videoDataOutput) {
            if (self->previewSyncStack < 1){
                self->previewSyncStack += 1;
                UIImage * previewImage = [self imageFromSampleBuffer:sampleBuffer];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_basePreviewView.image = previewImage;
                    self->_basePreviewView.contentMode = UIViewContentModeScaleAspectFit;
                    self->previewSyncStack -= 1;
                });
            }
        }
    }
    
    if(_isRecording && !haveStartedSession){
        [senbayAssetWriter   startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        [originalAssetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        haveStartedSession = YES;
    }else if (!_isRecording && haveStartedSession){
        return;
    }

    if(_isRecording){
        if (output == audioDataOutput) { // audio
            if (_config.isExportOriginalVideo) {
                if ([originalAudioInput isReadyForMoreMediaData]) {
                    [originalAudioInput appendSampleBuffer:sampleBuffer];
                }
            }
            if (_config.isExportSenbayVideo){
                if ([senbayAudioInput isReadyForMoreMediaData]) {
                    [senbayAudioInput appendSampleBuffer:sampleBuffer];
                }
            }
        } else if (output == videoDataOutput ){ // video
            if (_config.isExportOriginalVideo) {
                if ([originalVideoInput isReadyForMoreMediaData]) {
                    [originalVideoInput appendSampleBuffer:sampleBuffer];
                }
            }
            [self processVideoSampleBuffer:sampleBuffer];
            if (_config.isExportSenbayVideo){
                if ([senbayVideoInput isReadyForMoreMediaData]) {
                    [senbayVideoInput appendSampleBuffer:sampleBuffer];
                }
            }
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(senbayCaptureOutput:didOutputSampleBuffer:fromConnection:)]) {
        [self.delegate senbayCaptureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    }
    
    if(isBroadcast){
        if (output == audioDataOutput) { // audio
            [rtmpHandler processSampleBuffer:sampleBuffer withType:RPSampleBufferTypeAudioMic];
        } else if (output == videoDataOutput ){ // video
            [rtmpHandler processSampleBuffer:sampleBuffer withType:RPSampleBufferTypeVideo];
        }
    }
    
}

- (void )processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    NSString * qrcodeContent = [_sensorManager getFormattedData];
    [self setQRCodeContent:qrcodeContent];
    
    UIImage * qrCodeLayer = [self getQRCodeFilterLayer];
    CIImage * qrCodeLayerCGImage = [[CIImage alloc] initWithCGImage:qrCodeLayer.CGImage];
    
    // generate a pixelbuffer
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // clock the pixelbuffer
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );

    if (self->camouflageFlag) {
        CIImage   * captureUIImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CGImageRef videoImage = [camouflageContext
                                 createCGImage:captureUIImage
                                 fromRect:CGRectMake(0, 0,
                                                     CVPixelBufferGetWidth(pixelBuffer),
                                                     CVPixelBufferGetHeight(pixelBuffer))];
        // NSLog(@"x:%d, y:%d",(self->_qrCodeX) ,  (self->_qrCodeY) );
        [self camouflageQRCodeByColorOnCGImageRef:videoImage
                                                x: (self->_config.qrcodePositionX)
                                                y: (self->_config.qrcodePositionY)];
        CGImageRelease(videoImage);
        self->camouflageFlag = NO;
    }
    
    [eaglCIContext render:qrCodeLayerCGImage toCVPixelBuffer:pixelBuffer
                   bounds:CGRectMake(_config.qrcodePositionX,
                                     videoHeight-_config.qrcodePositionY-_config.qrcodeSize,
                                     _config.qrcodeSize,
                                     _config.qrcodeSize)
               colorSpace:CGColorSpaceCreateDeviceRGB()];
    
    CIImage *captureUIImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer];
    
    if (self->previewSyncStack < 1){
        self->previewSyncStack += 1;
        dispatch_async(dispatch_get_main_queue(), ^{
            CGImageRef videoImage = [self->previewCIContext
                                     createCGImage:captureUIImage
                                     fromRect:CGRectMake(0, 0,
                                                         CVPixelBufferGetWidth(pixelBuffer),
                                                         CVPixelBufferGetHeight(pixelBuffer))];
            // Rotate the UIImage if this device position is "portal"
            UIImageOrientation orientation = [self imageOrientationFromDeviceOrientation];
//            if ([self isNeededImageRotation]) {
//                orientation = UIImageOrientationRight;
//            }
            UIImage *previewImage = [UIImage imageWithCGImage:videoImage scale:1.0 orientation:orientation];
            CGImageRelease(videoImage);
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

            self->_basePreviewView.image = previewImage;
            self->_basePreviewView.contentMode = UIViewContentModeScaleAspectFit;
            self->previewSyncStack -= 1;
            
            if ([self.delegate respondsToSelector:@selector(didUpdateQRCodeContent:)]) {
                [self.delegate didUpdateQRCodeContent:qrcodeContent];
            }
            
            if ([self.delegate respondsToSelector:@selector(didUpdateVideoFrame:)]) {
                [self.delegate didUpdateVideoFrame:previewImage];
            }
            
        });
    }else{
        // NSLog(@"Preview Img Sync Stack: %d", self->previewImgGenStack);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    
//    ///////////////////////////////////
//    if (_config.isExportSenbayVideo){
//        if ([videoInput isReadyForMoreMediaData]) {
//            [self->videoInput appendSampleBuffer:sampleBuffer];
//        }
//    }
}

- (void)setQRCodeContent:(NSString *)content
{
    UIImage * qrcodeImg = [_qrcode generateQRCodeImageWithText:content
                                                    size:self->_config.qrcodeSize];
    UIImage * qrcodeLayer = [self generateQRCodeLayerWithBackgroundWidth:self->videoWidth
                                                        backgroundHeight:self->videoHeight
                                                             qrCodeImage:qrcodeImg
                                                                       x:self->_config.qrcodePositionX
                                                                       y:self->_config.qrcodePositionY];
    self->qrcodeLayer = qrcodeLayer;
}

- (UIImage *)getQRCodeFilterLayer
{
    return self->qrcodeLayer;
}


- (void)configureCameraForHighestFrameRate:(AVCaptureDevice *)device
                                      size:(AVCaptureSessionPreset)size
                                    maxFPS:(int)fps
{
    for ( AVCaptureDeviceFormat *format in device.formats) {
        if(_config.isDebug){
            NSLog(@"%@",format.debugDescription);
        }
    }
    
    BOOL breakFlag = NO;
    AVCaptureDeviceFormat *bestFormat = nil;
    AVFrameRateRange *bestFrameRateRange = nil;
    for ( AVCaptureDeviceFormat *format in device.formats ) {
        for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t vWidth = dimensions.width;
            // NSLog(@"[width] %d [range] %d",vWidth,(int)range.maxFrameRate);
            if (vWidth == (int)videoWidth && (int)range.maxFrameRate <= 60) {
                bestFormat = format;
                bestFrameRateRange = range;
                breakFlag = YES;
                break;
            }else{
                bestFormat = format;
                bestFrameRateRange = range;
            }
        }
        if (breakFlag) {
            break;
        }
    }
    
    if ( bestFormat ) {
        if ( [device lockForConfiguration:NULL] == YES ) {
            NSLog(@"[bestFormat] %@",bestFormat);
            [device setSmoothAutoFocusEnabled:YES];
            [device setAutomaticallyAdjustsVideoHDREnabled:YES];
            device.activeFormat = bestFormat;
            device.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
            device.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
            [device unlockForConfiguration];
        }
    }
}

- (UIImage *) generateQRCodeLayerWithBackgroundWidth:(float)width backgroundHeight:(float)height
                                         qrCodeImage:(UIImage *)qrCodeImage
                                                   x:(float)x
                                                   y:(float)y
{
    // generate background image
    UIImage * background = [self imageWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0] rect:CGRectMake(0, 0, width, height)];
    
    // mix background and qrcode image
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    [background drawInRect:CGRectMake(0, 0, width,height)];
    [qrCodeImage drawInRect:CGRectMake(x, y, qrCodeImage.size.width,  qrCodeImage.size.height)];
    background = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return background;
}


- (UIImage *)imageWithColor:(UIColor *)color
                       rect:(CGRect)rect
{
    // CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


/////// QR code color methods
- (void)camouflageQRCodeByColorOnCGImageRef:(CGImageRef)imageRef
                                          x:(int)x
                                          y:(int)y
{
    NSUInteger width  = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);

    CGColorSpaceRef colorSpace  = CGColorSpaceCreateDeviceRGB();
    unsigned char * rawData     = malloc(height * width * 4);
    NSUInteger bytesPerPixel    = 4;
    NSUInteger bytesPerRow      = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    unsigned long byteIndex = (bytesPerRow * x) + y * bytesPerPixel;

    int r = rawData[byteIndex];
    int g = rawData[byteIndex + 1];
    int b = rawData[byteIndex + 2];
    [_qrcode camouflageByBackgroundColorWithRead:r green:g blue:b];
    // unsigned long byteIndex = (x * 4) * y;

    free(rawData);
//    CFRelease(dataRef);
    
}

/**
 * Start recoding a Senbay video.(This method is called by -pushedCaptureButton:sender)
 */
- (void) startRecording
{
    bool isReady = [self activate];
    if(isReady){
        // AudioServicesPlaySystemSound(1117);
        // [self removeCameraPreview];
        double delayToStartRecording = 0.5;
        dispatch_time_t startT = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
        dispatch_after(startT, dispatch_get_main_queue(), ^(void){
            // start movie writer for senbay video
            // old // [self->senbayVideoWriter startRecording];
            self->haveStartedSession = NO;
            
            [self->senbayAssetWriter startWriting];
            [self->originalAssetWriter startWriting];
            
            if (self->_config.isDebug) NSLog(@"start...");
            // Start a timer for updating senbay data
            self->startTime = [NSDate date];
            self->mainTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                          target:self
                                                        selector:@selector(updateFormattedTime:)
                                                        userInfo:nil
                                                         repeats:YES];
            self->_isRecording = YES;

        });
    }
}


/**
 * Stop recoding a Senbay video.(This method is called by -pushedCaptureButton:sender)
 */
- (void) stopRecording
{
    if (self->_config.isDebug) NSLog(@"...stop");
    self->_isRecording = NO;
    //[_senbayPreviewView setHidden:YES];
    // [self setCameraPreview];
    
    dispatch_sync(cameraProcessingQueue, ^{
        
        [self->senbayVideoInput markAsFinished];
        [self->senbayAudioInput markAsFinished];
        [self->senbayAssetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"start to save video to photo library");
                if (self.config.isExportSenbayVideo) {
                    [self saveVideoToPhotoLibraryWithFilePath:self->_config.senbayVideoFileURL];
                }
                self->_formattedTime = @"00:00";
                [self->mainTimer invalidate];
                if (self->_config.isDebug) NSLog(@"...end");
            });
        }];
        
        [self->originalVideoInput markAsFinished];
        [self->originalAudioInput markAsFinished];
        [self->originalAssetWriter finishWritingWithCompletionHandler:^{
            if (self.config.isExportOriginalVideo) {
                [self saveVideoToPhotoLibraryWithFilePath:self->_config.originalVideoFileURL];
            }
        }];
        
        
    });
}


/////////////////////////////////////////////////////////////////
- (void) saveVideoToPhotoLibraryWithFilePath:(NSURL * _Nonnull )filePath
{
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    if (authStatus == PHAuthorizationStatusNotDetermined ||
        authStatus == PHAuthorizationStatusRestricted ||
        authStatus == PHAuthorizationStatusDenied ) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if(status == PHAuthorizationStatusAuthorized){
                [self saveVideoToPhotoLibraryWithFilePath:filePath];
            }else{
                if (self->_config.isDebug) {
                    NSLog(@"error in saveVideoToPhotoLibraryWithAuthentificationCheck");
                }
            }
        }];
    }else if(authStatus == PHAuthorizationStatusAuthorized){
        
        library = [PHPhotoLibrary sharedPhotoLibrary];
        [library performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:filePath];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                if (self->_config.isDebug) NSLog(@"Sucess to save a video (%@) into Photo Library.", filePath.absoluteString);
            }else{
                if (self->_config.isDebug) NSLog(@"**Fail** to save a video (%@) into Photo Library.", filePath.absoluteString);
                if (error != nil) NSLog(@"%@",error.debugDescription);
            }
        }];
    }
}

///////////////////////////////////////////
- (void)updateFormattedTime:(NSTimer *)timer
{
    NSDate *now = [NSDate date];
    float tmp = [now timeIntervalSinceDate:startTime];
    int hh = (int)(tmp / 3600); // hour
    int mm = (float)(tmp-(hh*3600))/60.0f; // min
    int ss = tmp-(hh*3600)-(mm*60);// sec
    NSString *time = @"";
    if(hh > 0){
        time = [NSString stringWithFormat:@"%02d:%02d:%02d",hh,mm,ss];
    }else{
        time = [NSString stringWithFormat:@"%02d:%02d",mm,ss];
    }
    _formattedTime = time;
    if ([self.delegate respondsToSelector:@selector(didUpdateFormattedRecordTime:)]) {
        [self.delegate didUpdateFormattedRecordTime:time];
    }
}

- (UIImageOrientation) imageOrientationFromDeviceOrientation
{
    return UIImageOrientationUp;
    // AVCaptureVideoOrientation orientation;
//    switch ([[UIDevice currentDevice] orientation]) {
//        case UIDeviceOrientationUnknown:
//            return UIImageOrientationUp;
//        case UIDeviceOrientationPortrait:
//            return UIImageOrientationRight; // ok
//        case UIDeviceOrientationPortraitUpsideDown:
//            return UIImageOrientationUp; //ok
//        case UIDeviceOrientationFaceUp:
//        //    return UIImageOrientationDown;
//        case UIDeviceOrientationFaceDown:
//        //   return UIImageOrientationUp; // ok
//        case UIDeviceOrientationLandscapeLeft:
//            return UIImageOrientationUp; //ok
//        case UIDeviceOrientationLandscapeRight:
//            return UIImageOrientationLeft; //ok
//    }
}
    

//static AVCaptureVideoOrientation videoOrientationFromDeviceOrientation(UIDeviceOrientation deviceOrientation)
//{
//    AVCaptureVideoOrientation orientation;
//    switch (deviceOrientation) {
//        case UIDeviceOrientationUnknown:
//            orientation = AVCaptureVideoOrientationPortrait;
//            break;
//        case UIDeviceOrientationPortrait:
//            orientation = AVCaptureVideoOrientationPortrait;
//            break;
//        case UIDeviceOrientationPortraitUpsideDown:
//            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
//            break;
//        case UIDeviceOrientationLandscapeLeft:
//            orientation = AVCaptureVideoOrientationLandscapeRight;
//            break;
//        case UIDeviceOrientationLandscapeRight:
//            orientation = AVCaptureVideoOrientationLandscapeLeft;
//            break;
//        case UIDeviceOrientationFaceUp:
//            orientation = AVCaptureVideoOrientationPortrait;
//            break;
//        case UIDeviceOrientationFaceDown:
//            orientation = AVCaptureVideoOrientationPortrait;
//            break;
//    }
//    return orientation;
//}

// サンプルバッファのデータからCGImageRefを生成する
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // ピクセルバッファのベースアドレスをロックする
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get information of the image
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // RGBの色空間
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                    width,
                                                    height,
                                                    8,
                                                    bytesPerRow,
                                                    colorSpace,
                                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(newContext);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    UIImageOrientation orientation = [self imageOrientationFromDeviceOrientation];
//    UIImageOrientation orientation = UIImageOrientationUp;
//    if ([self isNeededImageRotation]) { // if this device position is "portal"
//        orientation = UIImageOrientationRight;
//    }
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:orientation];
    
    CGImageRelease(cgImage);
    
    return image;
}

@end

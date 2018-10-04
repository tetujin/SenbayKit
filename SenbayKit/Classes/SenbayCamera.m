//
//  CoreSenbay.m
//
//  Created by Yuuki Nishiyama on 2018/06/27.
//  Copyright © 2018 Yuuki Nishiyama. All rights reserved.
//

#import "SenbayCamera.h"
#import "SenbayData.h"
#import <MobileCoreServices/UTCoreTypes.h>

@implementation SenbayCamera
{
    // Local photo library instance
    PHPhotoLibrary * library;

    // Video writer for senbay video
    AVAssetWriter * videoWriter;
    
    // QR code generator and filter
    CIFilter  * qrCodeFilter;
    CIContext * ciContext;
    
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
}

// @synthesize camera      = _camera;
@synthesize basePreviewView = _basePreviewView;
// @synthesize delegate    = _delegate;
@synthesize isDebug     = _isDebug;

- (instancetype) init
{
    return [self initWithPreviewView:nil];
}

- (instancetype)initWithPreviewView:(UIImageView *) previewView
{
    self = [super init];
    if (self) {
        // background color = white;
        qrBGColorRed    = 255;
        qrBGColorGreen  = 255;
        qrBGColorBlue   = 255;
        
        // block color = black;
        qrBLKColorRed   =   0;
        qrBLKColorGreen =   0;
        qrBLKColorBlue  =   0;
        
        // camouflageInterval
        _camouflageInterval  =   5;
        _camouflageColorDiff = 100;
        _isCamouflageQRCodeAutomatically = NO;
        
        // set preview view
        _basePreviewView  = previewView;
        
        // init a QR code generator
        qrCodeFilter  = [CIFilter filterWithName:@"CIQRCodeGenerator"];
        [qrCodeFilter setDefaults];
        ciContext         = [CIContext contextWithOptions:nil];
        previewCIContext  = [CIContext contextWithOptions:nil];
        camouflageContext = [CIContext contextWithOptions:nil];

        // init a URL for video file
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _videoFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"senbay_video.mov"]];
        library       = [PHPhotoLibrary sharedPhotoLibrary];
        
        // init camera settings
        _isRecording       = NO;
        _maxFPS            = 60;                                     // 60FPS
        _videoSize         = AVCaptureSessionPreset1280x720;         // 1280x720
        videoWidth         = 1280;
        videoHeight        = 720;
        _cameraPosition    = AVCaptureDevicePositionBack;            // back camera
        _cameraOrientation = UIInterfaceOrientationLandscapeRight;   // landscape
        _qrCodeSize        = videoWidth*0.15;
        _qrCodeX           = 0;
        _qrCodeY           = 0;
        _videoCodec        = AVVideoCodecH264;
        _videoFileType     = AVFileTypeQuickTimeMovie;
        threadSyncStack    = 0;
        qrCodeGenStack     = 0;
        previewSyncStack   = 0;
        previewImgGenStack = 0;
        
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
    return [self initCameraWithExportURL:_videoFileURL
                                    size:_videoSize
                                position:_cameraPosition
                             orientation:_cameraOrientation
                                   codec:_videoCodec
                                     fps:_maxFPS];
}

- (bool) deactivate
{
    // stop preview
    return YES;
}

- (bool) initCameraWithExportURL:(NSURL*) outputURL
                            size:(AVCaptureSessionPreset)size
                        position:(AVCaptureDevicePosition)position
                     orientation:(UIInterfaceOrientation)orientation
                           codec:(AVVideoCodecType)codec
                             fps:(int)fps
{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
    if (error!=nil) {
        if (_isDebug) NSLog(@"[SenbayCamera] %@", error.debugDescription);
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
    videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoDataOutput.videoSettings = settings;
    [videoDataOutput setSampleBufferDelegate:self queue:cameraProcessingQueue];
    
    audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioDataOutput setSampleBufferDelegate:self queue:audioProcessingQueue];
    
    //////////////////////////////////
    _captureSession = [[AVCaptureSession alloc] init];

    _captureSession.sessionPreset = _videoSize;
    
    [_captureSession addInput:cameraDeviceInput];
    [_captureSession addOutput:videoDataOutput];
    [_captureSession addInput:micDeviceInput];
    [_captureSession addOutput:audioDataOutput];
    
    
    NSError * assetWriterError = nil;
    senbayAssetWriter = [[AVAssetWriter alloc] initWithURL:outputURL
                                                  fileType:_videoFileType
                                                     error:&assetWriterError];
    
    if(size == AVCaptureSessionPreset3840x2160){
        videoWidth = 3840;
        videoHeight = 2160;
    }else if(size == AVCaptureSessionPreset1920x1080){
        videoWidth = 1920;
        videoHeight = 1080;
    }else if(size == AVCaptureSessionPreset1280x720){
        videoWidth = 1280;
        videoHeight = 720;
    }else if(size == AVCaptureSessionPreset640x480){
        videoWidth = 640;
        videoHeight = 480;
    }
    
    NSDictionary *outputSettings  = [NSDictionary dictionaryWithObjectsAndKeys:
                                      AVVideoCodecH264, AVVideoCodecKey, //1920x1080
                                      [NSNumber numberWithInt:videoWidth],  AVVideoWidthKey,
                                      [NSNumber numberWithInt:videoHeight], AVVideoHeightKey,
                                     nil ];
    videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    videoInput.expectsMediaDataInRealTime = YES;
    audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil];
    audioInput.expectsMediaDataInRealTime = YES;
    //if ([senbayAssetWriter  canAddInput:videoInput]) {
        [senbayAssetWriter  addInput:videoInput];
    //}
    //if ([senbayAssetWriter  canAddInput:audioInput]) {
        [senbayAssetWriter  addInput:audioInput];
    //}
    
    [_captureSession beginConfiguration];
    for ( AVCaptureConnection *connection in [videoDataOutput connections] ) {
        if ([connection isVideoOrientationSupported]) {
            [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
            // connection.videoOrientation = videoOrientationFromDeviceOrientation([UIDevice currentDevice].orientation);
        }
    }
    [_captureSession commitConfiguration];
    
    // Start recording
    [_captureSession startRunning];
    
    [self configureCameraForHighestFrameRate:_camera size:size maxFPS:fps];

    if (_isCamouflageQRCodeAutomatically){
        if(camouflageTimer != nil){
            [camouflageTimer invalidate];
            camouflageTimer = nil;
        }
        if (_isDebug) {
            NSLog(@"[SenbayCamera] Camouflage Interval   = %f second", _camouflageInterval);
            NSLog(@"[SenbayCamera] Camouflage Color Diff = %d (0-255)", _camouflageColorDiff);
        }
        [NSTimer scheduledTimerWithTimeInterval:_camouflageInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
            self->camouflageFlag = YES;
        }];
    }
    return YES;
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


- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
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
        [senbayAssetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        haveStartedSession = YES;
    }else if (!_isRecording && haveStartedSession){
        return;
    }

    if(_isRecording){
        // AudioとVideoのinputはそれぞれ処理するプロセスが違うので注意
        if (output == audioDataOutput) { // audio
            if ([audioInput isReadyForMoreMediaData]) {
                [audioInput appendSampleBuffer:sampleBuffer];
            }
        } else { // video
            [self processVideoSampleBuffer:sampleBuffer];
        }
    }else{

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
                                                x: (self->_qrCodeX)
                                                y: (self->_qrCodeY)];
        CGImageRelease(videoImage);
        self->camouflageFlag = NO;
    }
    
    [eaglCIContext render:qrCodeLayerCGImage toCVPixelBuffer:pixelBuffer
                   bounds:CGRectMake(_qrCodeX, videoHeight-_qrCodeY-_qrCodeSize, _qrCodeSize, _qrCodeSize)
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
        NSLog(@"Preview Img Sync Stack: %d", self->previewImgGenStack);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    
    ///////////////////////////////////
    if ([videoInput isReadyForMoreMediaData]) {
        [self->videoInput appendSampleBuffer:sampleBuffer];
    }
}

- (void)setQRCodeContent:(NSString *)content
{
    UIImage * qrcode = [self generateQRCodeImageWithText:content
                                                    size:self->_qrCodeSize];
    UIImage * qrcodeLayer = [self generateQRCodeLayerWithBackgroundWidth:self->videoWidth
                                                        backgroundHeight:self->videoHeight
                                                             qrCodeImage:qrcode
                                                                       x:self->_qrCodeX
                                                                       y:self->_qrCodeY];
    self->qrCodeLayer = qrcodeLayer;
}

- (UIImage *)getQRCodeFilterLayer
{
    return self->qrCodeLayer;
}


- (void)configureCameraForHighestFrameRate:(AVCaptureDevice *)device
                                      size:(AVCaptureSessionPreset)size
                                    maxFPS:(int)fps
{
    for ( AVCaptureDeviceFormat *format in device.formats) {
        NSLog(@"%@",format.debugDescription);

    }
    
    BOOL breakFlag = NO;
    AVCaptureDeviceFormat *bestFormat = nil;
    AVFrameRateRange *bestFrameRateRange = nil;
    for ( AVCaptureDeviceFormat *format in device.formats ) {
        for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t vWidth = dimensions.width;
            if (vWidth == videoWidth && range.maxFrameRate == 60) {
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


- (UIImage *) generateQRCodeImageWithText:(NSString *)text size:(float)size
{
    UIImage *image = nil;
    @autoreleasepool {
        // generate data for QR code
        NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
        [qrCodeFilter setValue:data forKey:@"inputMessage"];
        [qrCodeFilter setValue:@"L" forKey:@"inputCorrectionLevel"];

        // L: 7%  -> 4,296 bytes
        // M: 15% -> 3,391 bytes
        // Q: 25% -> 2,420 bytes
        // H: 30% -> 1,852 bytes
        
        // convert CGImage to UIImage
        CIImage * qrcode = [qrCodeFilter outputImage];
        
        CGImageRef cgimg = [ciContext createCGImage:qrcode fromRect:[qrcode extent]];
        
        if (![self isWhite:qrBGColorRed green:qrBGColorGreen blue:qrBGColorBlue] ||
            ![self isBlack:qrBLKColorRed green:qrBLKColorGreen blue:qrBLKColorBlue]) {
            NSUInteger width            = CGImageGetWidth(cgimg);
            NSUInteger height           = CGImageGetHeight(cgimg);
            CGColorSpaceRef colorSpace  = CGColorSpaceCreateDeviceRGB();
            unsigned char *rawData      = malloc(height * width * 4);
            NSUInteger bytesPerPixel    = 4;
            NSUInteger bytesPerRow      = bytesPerPixel * width;
            NSUInteger bitsPerComponent = 8;
            CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            CGColorSpaceRelease(colorSpace);
            
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgimg);
            CGContextRelease(context);
            
            // Now your rawData contains the image data in the RGBA8888 pixel format.
            int x = 0;
            int y = 0;
            for(x=0; x<width; x++){
                for(y=0; y<height; y++){
                    long long byteIndex = (bytesPerRow * x) + y * bytesPerPixel;
                    int r = rawData[byteIndex];
                    int g = rawData[byteIndex + 1];
                    int b = rawData[byteIndex + 2];
                    // int a = rawData[byteIndex + 3];
                    if(r==0 && g==0 && b==0){ // convert a black block
                        if (![self isBlack:qrBLKColorRed green:qrBLKColorGreen blue:qrBLKColorBlue]) {
                            rawData[byteIndex] = qrBLKColorRed ; // r
                            rawData[byteIndex + 1] = qrBLKColorGreen; // g
                            rawData[byteIndex + 2] = qrBLKColorBlue ; // b
                            // rawData[byteIndex + 3] = components[3] * 255; // a
                        }
                    } else if(r==255 && g==255 && b==255){ // convert a white block
                        if(![self isWhite:qrBGColorRed green:qrBGColorGreen blue:qrBGColorBlue]){
                            rawData[byteIndex] = qrBGColorRed ; // r
                            rawData[byteIndex + 1] = qrBGColorGreen; // g
                            rawData[byteIndex + 2] = qrBGColorBlue ; // b
                            // rawData[byteIndex + 3] = components[3] * 255; // a
                        }
                    }
                }
            }
            
            CGImageRelease(cgimg);
            
            // generate a new CGImage with the new raw data (new color)
            CGContextRef newcontext = CGBitmapContextCreate (rawData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
            CGImageRef imageRef = CGBitmapContextCreateImage(newcontext);
            CGContextRelease(newcontext);
            CGColorSpaceRelease(colorSpace);
            
            // generate a new NSImage using the CGImage
            image = [[UIImage alloc] initWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationUp];
            CGImageRelease(imageRef);
            
            free(rawData);
        }else{
            // generate a UIImage using the CIImage
            image = [UIImage imageWithCGImage:cgimg scale:1.0f orientation:UIImageOrientationUp];
            CGImageRelease(cgimg);
        }
        
        // scale the generated QR code
        UIGraphicsBeginImageContext(CGSizeMake(size, size));
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetInterpolationQuality(context, kCGInterpolationNone); // set an interpolation method
        [image drawInRect:CGRectMake(0, 0, size, size)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

- (UIImage *) fillImage:(UIImage *)baseImage
              withColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 24, 24);
    
    UIImage *image = [baseImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    
    [color setFill];
    [image drawInRect:rect];
    
    UIImage *editedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return editedImage;
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
    
    //////////////////////
//    UIImage * img = [UIImage imageWithCGImage:imageRef];
//    UIImage * frame = [self imageWithColor:UIColor.redColor rect:CGRectMake(0, 0, _qrCodeSize , _qrCodeSize)];
//    // グラフィックスコンテキストを作る
//    CGSize size = { img.size.width, img.size.height};
//    UIGraphicsBeginImageContext(size);
//
//    [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
//    [frame drawInRect:CGRectMake(_qrCodeX, _qrCodeY, _qrCodeSize, _qrCodeSize)];
//
//    // 合成した画像を取得する
//    UIImage* compositeImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    //////////////////////
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    unsigned long byteIndex = (bytesPerRow * x) + y * bytesPerPixel;

    qrBGColorRed   = rawData[byteIndex];
    qrBGColorGreen = rawData[byteIndex + 1];
    qrBGColorBlue  = rawData[byteIndex + 2];
    // unsigned long byteIndex = (x * 4) * y;

    
    double comp = (qrBGColorRed + qrBGColorGreen+qrBGColorBlue)/3;
    if (comp > 127) {
//        qrBLKColorRed   = 0;
//        qrBLKColorGreen = 0;
//        qrBLKColorBlue  = 0;
        qrBLKColorRed   = qrBGColorRed   - _camouflageColorDiff ;
        qrBLKColorGreen = qrBGColorGreen - _camouflageColorDiff;
        qrBLKColorBlue  = qrBGColorBlue  - _camouflageColorDiff;
        if(qrBLKColorRed   < 0)  qrBLKColorRed =0;
        if(qrBLKColorGreen < 0)  qrBLKColorGreen =0;
        if(qrBLKColorBlue  < 0)  qrBLKColorBlue =0;
    }else{
//        qrBLKColorRed   = 255;
//        qrBLKColorGreen = 255;
//        qrBLKColorBlue  = 255;
        qrBLKColorRed   = qrBGColorRed   + _camouflageColorDiff;
        qrBLKColorGreen = qrBGColorGreen + _camouflageColorDiff;
        qrBLKColorBlue  = qrBGColorBlue  + _camouflageColorDiff;
        if(qrBLKColorRed   > 255)   qrBLKColorRed =255;
        if(qrBLKColorGreen > 255) qrBLKColorGreen =255;
        if(qrBLKColorBlue  > 255)  qrBLKColorBlue =255;
    }

    free(rawData);
//
//    CFRelease(dataRef);
    
}

- (void)setQRCodeBackgroundColor:(UIColor *)color
{
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    int r = components[0] * 255 ; // r
    int g = components[1] * 255 ; // g
    int b = components[2] * 255 ; // b
    [self setQRCodeBackgroundColorWithRead:r green:g blue:b];
}

- (void)setQRCodeBlockColor:(UIColor *)color
{
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    int r = components[0] * 255 ; // r
    int g = components[1] * 255 ; // g
    int b = components[2] * 255 ; // b
    [self setQRCodeBlockColorWithRead:r green:g blue:b];
}

- (void)setQRCodeBackgroundColorWithRead:(int)r
                                   green:(int)g
                                    blue:(int)b
{
    qrBGColorRed = r;
    qrBGColorGreen = g;
    qrBGColorBlue = b;
}

- (void)setQRCodeBlockColorWithRead:(int)r
                              green:(int)g
                               blue:(int)b
{
    qrBLKColorRed = r;
    qrBLKColorGreen = g;
    qrBLKColorBlue = b;
}


- (BOOL) isWhite:(int)r
           green:(int)g
            blue:(int)b
{
    if (r==255 && g==255 && b==255){
        return YES;
    }else{
        return NO;
    }
}

- (BOOL) isBlack:(int)r
           green:(int)g
            blue:(int)b
{
    if (r==0 && g==0 && b==0){
        return YES;
    }else{
        return NO;
    }
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
            
            if (self-> _isDebug) NSLog(@"start...");
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
    if (self->_isDebug) NSLog(@"...stop");
    self->_isRecording = NO;
    //[_senbayPreviewView setHidden:YES];
    // [self setCameraPreview];
    
    dispatch_sync(cameraProcessingQueue, ^{
        [self->videoInput markAsFinished];
        [self->audioInput markAsFinished];
        [self->senbayAssetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"start to save video to photo library");
                [self saveVideoToPhotoLibraryWithAuthentificationCheck];
                self->_formattedTime = @"00:00";
                [self->mainTimer invalidate];
                // AudioServicesPlaySystemSound(1118);
                if (self->_isDebug) NSLog(@"...end");
            });
        }];
    });
}


/////////////////////////////////////////////////////////////////
- (void) saveVideoToPhotoLibraryWithAuthentificationCheck
{
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    if (authStatus == PHAuthorizationStatusNotDetermined ||
        authStatus == PHAuthorizationStatusRestricted ||
        authStatus == PHAuthorizationStatusDenied ) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if(status == PHAuthorizationStatusAuthorized){
                [self saveVideoToPhotoLibrary];
            }else{
                if (self->_isDebug) {
                    NSLog(@"error in saveVideoToPhotoLibraryWithAuthentificationCheck");
                }
            }
        }];
    }else if(authStatus == PHAuthorizationStatusAuthorized){
        [self saveVideoToPhotoLibrary];
    }
}

- (void) saveVideoToPhotoLibrary
{
    library = [PHPhotoLibrary sharedPhotoLibrary];
    [library performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self->_videoFileURL];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            if (self->_isDebug) NSLog(@"Sucess to save the video to Photo Library.");
        }else{
            if (self->_isDebug) NSLog(@"**Fail** to save the video to Photo Library.");
            if (error != nil) NSLog(@"%@",error.debugDescription);
        }
    }];
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

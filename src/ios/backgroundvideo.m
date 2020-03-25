#import "backgroundvideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@implementation backgroundvideo

@synthesize parentView, view, session, output, outputPath, previewLayer;

#ifndef __IPHONE_3_0
@synthesize webView;
#endif

#pragma mark -
#pragma mark backgroundvideo

-(void) pluginInitialize{
  // start as transparent
  self.webView.opaque = NO;
  self.webView.backgroundColor = [UIColor clearColor];
}


- (void) initPreview:(CDVInvokedUrlCommand *)command
{
    NSString* camera = [command.arguments objectAtIndex:0];
    id x = [command.arguments objectAtIndex:1];
    id y = [command.arguments objectAtIndex:2];
    id width = [command.arguments objectAtIndex:3];
    id height = [command.arguments objectAtIndex:4];

    self.view.alpha = 0;

    //make the view
    CGRect viewRect = CGRectMake( [x floatValue], [y floatValue], [width floatValue], [height floatValue] );

    self.parentView = [[UIView alloc] initWithFrame:viewRect];

    self.view = [[UIView alloc] initWithFrame: self.parentView.bounds];
    [self.parentView addSubview: view];
    self.parentView.userInteractionEnabled = NO;


    //Capture session
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPreset640x480];

    //capture device output
    CMTime maxDuration = CMTimeMakeWithSeconds(1800, 1);

    output = [[AVCaptureMovieFileOutput alloc] init];
    output.maxRecordedDuration = maxDuration;
    output.movieFragmentInterval = kCMTimeInvalid;

    if ([session canAddOutput:output]) [session addOutput:output];


    //Capture camera input
    AVCaptureDevice *inputDevice = [self getCamera:camera];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];

    if ([session canAddInput:deviceInput]) [session addInput:deviceInput];


    //Capture audio input
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:nil];

    if ([session canAddInput:audioInput]) [session addInput:audioInput];


    //preview view
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;

    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    [self.previewLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height)];
    [rootLayer insertSublayer:self.previewLayer atIndex:0];

    [self setCaptureConnectionOrientation:self.previewLayer.connection];


    [session startRunning];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) enablePreview:(CDVInvokedUrlCommand *)command
{
    [self.webView.superview addSubview:self.parentView];

    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    [self.webView.superview bringSubviewToFront:self.webView];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) disablePreview:(CDVInvokedUrlCommand *)command
{
    [self.parentView removeFromSuperview];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) updatePreview:(CDVInvokedUrlCommand *)command
{
    id x = [command.arguments objectAtIndex:0];
    id y = [command.arguments objectAtIndex:1];
    id width = [command.arguments objectAtIndex:2];
    id height = [command.arguments objectAtIndex:3];

    CGRect viewRect = CGRectMake( [x floatValue], [y floatValue], [width floatValue], [height floatValue] );

    [self.parentView setFrame:viewRect];
    [self.view setFrame:self.parentView.bounds];

    CALayer *rootLayer = [self.view layer];
    [self.previewLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height)];

    [self setCaptureConnectionOrientation:self.previewLayer.connection];
    if ([output isRecording]) {
        AVCaptureConnection *outputConnection = [output connectionWithMediaType:AVMediaTypeVideo];
        [self setCaptureConnectionOrientation:outputConnection];
    }

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) startRecording:(CDVInvokedUrlCommand *)command
{
    [output stopRecording];

    NSString* token = [command.arguments objectAtIndex:0];

    AVCaptureConnection *outputConnection = [output connectionWithMediaType:AVMediaTypeVideo];

    [self setCaptureConnectionOrientation:outputConnection];

    outputPath = [self getFileName:token];
    NSURL *fileURI = [[NSURL alloc] initFileURLWithPath:outputPath];

    [output startRecordingToOutputFileURL:fileURI recordingDelegate:self];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) stopRecording:(CDVInvokedUrlCommand *)command
{
    [output stopRecording];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:outputPath];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) stopAll:(CDVInvokedUrlCommand *)command
{
    if ([output isRecording]) [output stopRecording];
    [session stopRunning];
    [self.parentView removeFromSuperview];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) setCaptureConnectionOrientation:(AVCaptureConnection *)conn
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    if ([conn isVideoOrientationSupported]) {
        switch (interfaceOrientation) {
            case UIInterfaceOrientationPortrait: //portrait
                [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
                break;
            case UIInterfaceOrientationLandscapeRight: //home button on right
                [conn setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                break;
            case UIInterfaceOrientationLandscapeLeft: //home button on left
                [conn setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                break;
            default: //portrait upside down
                [conn setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
        }
    }
}


- (NSString *) getFileName:(NSString *)token
{
    int fileNameIncrementer = 1;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *libPath = [self getCachePath];

    NSString *tempPath = [[NSString alloc] initWithFormat:@"%@%@%@", libPath, token, FileExtension];

    while ([fileManager fileExistsAtPath:tempPath]) {
        tempPath = [NSString stringWithFormat:@"%@%@_%i%@", libPath, token, fileNameIncrementer, FileExtension];
        fileNameIncrementer++;
    }

    return tempPath;
}


- (NSString*) getCachePath
{
    NSString* cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    return [NSString stringWithFormat:@"%@/", cachePath];
}


- (AVCaptureDevice *) getCamera:(NSString *)camera
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if([camera caseInsensitiveCompare:@"front"] == NSOrderedSame)
        {
            if (device.position == AVCaptureDevicePositionFront )
            {
                captureDevice = device;
                break;
            }
        }
        else if ([camera caseInsensitiveCompare:@"BACK"] == NSOrderedSame)
        {
            if (device.position == AVCaptureDevicePositionBack )
            {
                captureDevice = device;
                break;
            }
        }
        else
        {
            //TODO: return cordova error
            NSLog(@"Coudn't find camera");
        }
    }
    return captureDevice;
}


- (void) captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
}


@end

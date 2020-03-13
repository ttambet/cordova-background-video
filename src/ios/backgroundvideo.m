#import "backgroundvideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@implementation backgroundvideo

@synthesize parentView, view, session, output, outputPath, isFinished, previewLayer;

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

- (void) start:(CDVInvokedUrlCommand *)command
{
    [output stopRecording];
    self.view.alpha = 0;
    //stop the device from being able to sleep
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    // filename, camera
    self.token = [command.arguments objectAtIndex:0];
    self.camera = [command.arguments objectAtIndex:1];
    id x = [command.arguments objectAtIndex:2];
    id y = [command.arguments objectAtIndex:3];
    id width = [command.arguments objectAtIndex:4];
    id height = [command.arguments objectAtIndex:5];

    //get rid of the old view (causes issues if the app is resumed)
    self.parentView = nil;

    //make the view
    CGRect viewRect = CGRectMake( [x floatValue], [y floatValue], [width floatValue], [height floatValue] );

    self.parentView = [[UIView alloc] initWithFrame:viewRect];
    [self.webView.superview addSubview:self.parentView];

    self.view = [[UIView alloc] initWithFrame: self.parentView.bounds];
    [self.parentView addSubview: view];
    self.parentView.userInteractionEnabled = NO;

    //camera stuff

    //Capture session
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetHigh];

    //Get the front camera and set the capture device
    AVCaptureDevice *inputDevice = [self getCamera: self.camera];


    //write the file
    outputPath = [self getFileName];
    NSURL *fileURI = [[NSURL alloc] initFileURLWithPath:outputPath];

    //capture device output
    CMTime maxDuration = CMTimeMakeWithSeconds(1800, 1);

    output = [[AVCaptureMovieFileOutput alloc]init];
    output.maxRecordedDuration = maxDuration;
    output.movieFragmentInterval = kCMTimeInvalid;


    if ( [session canAddOutput:output])
        [session addOutput:output];

    //Capture audio input
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:nil];

    if ([session canAddInput:audioInput])
        [session addInput:audioInput];

    //Capture device input
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    if ( [session canAddInput:deviceInput] )
        [session addInput:deviceInput];


    //preview view
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    [self.previewLayer setFrame:CGRectMake(0, 0, rootLayer.bounds.size.width, rootLayer.bounds.size.height)];
    [rootLayer insertSublayer:self.previewLayer atIndex:0];

    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

    AVCaptureConnection *previewLayerConnection = self.previewLayer.connection;
    AVCaptureConnection *outputConnection = [output connectionWithMediaType:AVMediaTypeVideo];


    if ([previewLayerConnection isVideoOrientationSupported]) {
        switch (interfaceOrientation)
        {
            case UIInterfaceOrientationPortrait:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                [outputConnection setVideoOrientation:AVCaptureVideoOrientationPortrait]; //portrait
                break;
            case UIInterfaceOrientationLandscapeRight:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                [outputConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight]; //home button on right.
                break;
            case UIInterfaceOrientationLandscapeLeft:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                [outputConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft]; //home button on left.
                break;
            default:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
                [outputConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown]; //portrait upside down
                break;
        }
    }

    //go
    [session startRunning];
    [output startRecordingToOutputFileURL:fileURI recordingDelegate:self ];

    //return true to ensure callback fires
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stop:(CDVInvokedUrlCommand *)command
{
    [output stopRecording];
    //self.view.alpha = 0;

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:outputPath];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopCamera:(CDVInvokedUrlCommand *)command
{
    [output stopRecording];
    self.view.alpha = 0;

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:outputPath];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


-(NSString*)getFileName
{
    int fileNameIncrementer = 1;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *libPath = [self getCachePath];

    NSString *tempPath = [[NSString alloc] initWithFormat:@"%@%@%@", libPath, self.token, FileExtension];

    while ([fileManager fileExistsAtPath:tempPath]) {
        tempPath = [NSString stringWithFormat:@"%@%@_%i%@", libPath, self.token, fileNameIncrementer, FileExtension];
        fileNameIncrementer++;
    }

    return tempPath;
}

-(NSString*)getLibraryPath
{
    NSArray *lib = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *library = [lib objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/NoCloud/", library];
}

-(NSString*)getCachePath
{
    NSString* cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    return [NSString stringWithFormat:@"%@/", cachePath];
}

-(AVCaptureDevice *)getCamera: (NSString *)camera
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

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
}

@end

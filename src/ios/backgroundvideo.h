#import <UIKit/UIKit.h>

#import <Cordova/CDVPlugin.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#define FileExtension @".mp4"

@interface backgroundvideo : CDVPlugin <UITabBarDelegate, AVCaptureFileOutputRecordingDelegate> {
}

@property AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain) UIView *parentView;
@property (nonatomic, retain) UIView *view;
@property AVCaptureSession *session;
@property AVCaptureMovieFileOutput *output;
@property NSString *outputPath;

- (void)initPreview:(CDVInvokedUrlCommand *)command;
- (void)enablePreview:(CDVInvokedUrlCommand *)command;
- (void)disablePreview:(CDVInvokedUrlCommand *)command;
- (void)updatePreview:(CDVInvokedUrlCommand *)command;
- (void)startRecording:(CDVInvokedUrlCommand *)command;
- (void)stopRecording:(CDVInvokedUrlCommand *)command;

@end

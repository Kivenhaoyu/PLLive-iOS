//
//  PLViewController.m
//  PLStreamingKit
//
//  Created by 0dayZh on 11/04/2015.
//  Copyright (c) 2015 0dayZh. All rights reserved.
//

#import "PLViewController.h"

const char *stateNames[] = {
    "Unknow",
    "Connecting",
    "Connected",
    "Disconnecting",
    "Disconnected",
    "Error"
};

@interface PLViewController ()

@property (nonatomic, strong) NSString * userOROfficeName;
@property (nonatomic, assign) NSInteger qualityNum;
@property (nonatomic, assign) NSInteger audioQualityNum;
@property (nonatomic, strong) NSString * quality;
@property (nonatomic, strong) NSString * audioQuality;

@end

@implementation PLViewController

- (instancetype)initWithKey:(NSString *)userOrOfficeName
                withQuality:(NSInteger) qualityNum
           withAudioQualiyt:(NSInteger) audioQualityNum
{
    self = [super init];
    if (self) {
        self.userOROfficeName = userOrOfficeName;
        NSString * qualityString;
        switch (qualityNum) {
            case 0:
                qualityString = kPLVideoStreamingQualityLow1;
                break;
            case 1:
                qualityString = kPLVideoStreamingQualityLow2;
                break;
            case 2:
                qualityString = kPLVideoStreamingQualityLow3;
                break;
            case 3:
                qualityString = kPLVideoStreamingQualityMedium1;
                break;
            case 4:
                qualityString = kPLVideoStreamingQualityMedium2;
                break;
            case 5:
                qualityString = kPLVideoStreamingQualityMedium3;
                break;
            case 6:
                qualityString = kPLVideoStreamingQualityHigh1;
                break;
            case 7:
                qualityString = kPLVideoStreamingQualityHigh2;
                break;
            case 8:
                qualityString = kPLVideoStreamingQualityHigh3;
                break;
                
            default:
                qualityString = kPLVideoStreamingQualityLow2;
                self.qualityNum =1;
                break;
        }
        self.quality = qualityString;
        
        NSString * audioQualityString;
        switch (audioQualityNum) {
            case 0:
                audioQualityString = kPLAudioStreamingQualityHigh1;
                break;
            case 1:
                audioQualityString = kPLAudioStreamingQualityHigh2;
                break;
                
            default:
                audioQualityString = kPLAudioStreamingQualityHigh1;
                break;
        }
        self.audioQuality = audioQualityString;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"录制";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
    [self setUpUI];
    
    [self initCaptureSource];
}

- (void)setUpUI
{
    self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake((kDeviceWidth-60)/2, KDeviceHeight-100, 60, 40)];
    [self.actionButton setTitle:@"start" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.actionButton];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.captureSession stopRunning];
    self.streamingController = nil;
}

#pragma mark - Notification

- (void)handleInterruption:(NSNotification *)notification {
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        NSLog(@"Interruption notification");
        
        if ([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] isEqualToNumber:[NSNumber numberWithInt:AVAudioSessionInterruptionTypeBegan]]) {
            NSLog(@"InterruptionTypeBegan");
        } else {
            // the facetime iOS 9 has a bug: 1 does not send interrupt end 2 you can use application become active, and repeat set audio session acitve until success.  ref http://blog.corywiles.com/broken-facetime-audio-interruptions-in-ios-9
            NSLog(@"InterruptionTypeEnded");
            setSamplerate();
        }
    }
}

#pragma mark - Streaming

- (void)start {
    if (!self.streamingController) {
        NSTimeInterval date = [[NSDate date] timeIntervalSince1970] *1000;
        NSString *urlString = [NSString stringWithFormat:@"rtmp://cloudvdn.pili.cloudvdn.publish:1835/%@/ios/%.0f",self.userOROfficeName,date ];
        NSURL *url = [[NSURL alloc]initWithString:urlString];
        NSString *log = [NSString stringWithFormat:@"publish URL: %@", url];
        NSLog(@"%@", log);
        
//        self.streamingController = [PLStreaming startWithPushURL:url delegate:self];
        
        self.streamingController = [PLStreaming startWithPushURL:url videoEncodingConfiguration:[PLVideoEncodingConfiguration configurationWithVideoSize:CGSizeMake(640, 720) videoQuality:self.quality] audioEncodingConfiguration:[PLAudioEncodingConfiguration configurationWithAudioQuality:self.audioQuality] networkConfiguration:[PLNetworkConfiguration defaultConfiguration] delegate:self delegateQueue:dispatch_get_main_queue()];
    } else {
        [self.streamingController restart];
    }
}

- (void)stop {
    [self.streamingController stop];
}


#pragma mark - Action

- (void)actionButtonPressed:(id)sender {
    self.actionButton.enabled = NO;
    
    if (self.isRunning) {
        [self stop];
        [self.actionButton setTitle:@"Start" forState:UIControlStateNormal];
        self.actionButton.enabled = YES;
    } else {
        [self start];
    }
}

#pragma mark - <PLStreamingDelegate>

- (void)streamingStateDidChange:(PLStreamState)state {
    NSString *log = [NSString stringWithFormat:@"Stream State: %s", stateNames[state]];
    NSLog(@"%@", log);
    
    self.isRunning = (state == PLStreamStateConnected);
    NSString *title = @"Start";
    
    switch (state) {
        case PLStreamStateConnecting:
        case PLStreamStateDisconnecting:
            self.actionButton.enabled = NO;
            break;
        case PLStreamStateConnected:
            title = @"Stop";
        case PLStreamStateDisconnected:
            self.actionButton.enabled = YES;
            break;
        default:
            break;
    }
    
    [self.actionButton setTitle:title forState:UIControlStateNormal];
}

- (void)streamingDidDisconnectWithError:(NSError *)error {
    self.actionButton.enabled = YES;
    NSString *log = [NSString stringWithFormat:@"Stream State: Error. %@", error];
    NSLog(@"%@", log);
    [self.actionButton setTitle:@"Start" forState:UIControlStateNormal];
}

- (void)streamingStatusDidUpdate:(PLStreamStatus *)status {
    NSLog(@"%@", status);
}

- (void)streamingSendingBufferDidEmpty {}

- (void)streamingSendingBufferDidFull {}

#pragma mark - <AVCaptureVideoDataOutputSampleBufferDelegate>

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!self.isRunning) {
        return;
    }
    
    if (captureOutput == self.cameraCaptureOutput) {
        [self.streamingController pushVideoSampleBuffer:sampleBuffer];
    } else if (captureOutput == self.microphoneCaptureOutput) {
        [self.streamingController pushAudioSampleBuffer:sampleBuffer];
    }
}

#pragma mark - camera source

static void setSamplerate(){
    NSError *err;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setPreferredSampleRate:session.sampleRate error:&err];
    if (err != nil) {
        NSString *log = [NSString stringWithFormat:@"set samplerate failed, %@", err];
        NSLog(@"%@", log);
        return;
    }
    if (![session setActive:YES error:&err]) {
        NSString *log = @"Failed to set audio session active.";
        NSLog(@"%@ %@", log, err);
    }
}

- (void)initCaptureSource {
    __weak typeof(self) wself = self;
    void (^permissionGranted)(void) = ^{
        __strong typeof(wself) strongSelf = wself;
        
        NSArray *devices = [AVCaptureDevice devices];
        for (AVCaptureDevice *device in devices) {
            if ([device hasMediaType:AVMediaTypeVideo] && AVCaptureDevicePositionBack == device.position) {
                strongSelf.cameraCaptureDevice = device;
                break;
            }
        }
        
        if (!strongSelf.cameraCaptureDevice) {
            NSString *log = @"No back camera found.";
            NSLog(@"%@", log);
            return ;
        }
        
        AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
        AVCaptureDeviceInput *input = nil;
        AVCaptureVideoDataOutput *output = nil;
        
        input = [[AVCaptureDeviceInput alloc] initWithDevice:strongSelf.cameraCaptureDevice error:nil];
        output = [[AVCaptureVideoDataOutput alloc] init];
        
        strongSelf.cameraCaptureOutput = output;
        
        [captureSession beginConfiguration];
        captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        
        // setup output
        output.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
        
        dispatch_queue_t cameraQueue = dispatch_queue_create("com.pili.camera", 0);
        [output setSampleBufferDelegate:strongSelf queue:cameraQueue];
        
        // add input && output
        if ([captureSession canAddInput:input]) {
            [captureSession addInput:input];
        }
        
        if ([captureSession canAddOutput:output]) {
            [captureSession addOutput:output];
        }
        
        NSLog(@"%@", [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]);
        
        // audio capture device
        AVCaptureDevice *microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:microphone error:nil];
        AVCaptureAudioDataOutput *audioOutput = nil;
        
        if ([captureSession canAddInput:audioInput]) {
            [captureSession addInput:audioInput];
        }
        audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        
        self.microphoneCaptureOutput = audioOutput;
        
        if ([captureSession canAddOutput:audioOutput]) {
            [captureSession addOutput:audioOutput];
        } else {
            NSLog(@"Couldn't add audio output");
        }
        
        dispatch_queue_t audioProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
        [audioOutput setSampleBufferDelegate:self queue:audioProcessingQueue];
        
        [captureSession commitConfiguration];
        
        NSError *error;
        [strongSelf.cameraCaptureDevice lockForConfiguration:&error];
        strongSelf.cameraCaptureDevice.activeVideoMinFrameDuration = CMTimeMake(1.0, 30);
        strongSelf.cameraCaptureDevice.activeVideoMaxFrameDuration = CMTimeMake(1.0, 30);
        [strongSelf.cameraCaptureDevice unlockForConfiguration];
        
        strongSelf.captureSession = captureSession;
        
        [strongSelf reorientCamera:AVCaptureVideoOrientationPortrait];
        
        AVCaptureVideoPreviewLayer* previewLayer;
        previewLayer =  [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        __weak typeof(strongSelf) wself1 = strongSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(wself1) strongSelf1 = wself1;
            previewLayer.frame = strongSelf1.view.layer.bounds;
            [strongSelf1.view.layer insertSublayer:previewLayer atIndex:0];
        });
        
        [strongSelf.captureSession startRunning];
    };
    
    void (^noPermission)(void) = ^{
        NSString *log = @"No camera permission.";
        NSLog(@"%@", log);
    };
    
    void (^requestPermission)(void) = ^{
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                permissionGranted();
            } else {
                noPermission();
            }
        }];
    };
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusAuthorized:
            permissionGranted();
            break;
        case AVAuthorizationStatusNotDetermined:
            requestPermission();
            break;
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
        default:
            noPermission();
            break;
    }
}

- (void)reorientCamera:(AVCaptureVideoOrientation)orientation {
    if (!self.captureSession) {
        return;
    }
    
    AVCaptureSession* session = (AVCaptureSession *)self.captureSession;
    
    for (AVCaptureVideoDataOutput* output in session.outputs) {
        for (AVCaptureConnection * av in output.connections) {
            if (av.isVideoOrientationSupported) {
                av.videoOrientation = orientation;
            }
        }
    }
}

@end

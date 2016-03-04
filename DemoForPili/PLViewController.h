//
//  PLViewController.h
//  PLStreamingKit
//
//  Created by 0dayZh on 11/04/2015.
//  Copyright (c) 2015 0dayZh. All rights reserved.
//

@import UIKit;
@import AVFoundation;

#import <PLStreamingKit/PLStreamingKit.h>

@interface PLViewController : UIViewController
<
AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate,
PLStreamingDelegate
>

@property (nonatomic, strong) id<PLStreamingControllerType>    streamingController;

@property (nonatomic, strong) AVCaptureSession  *captureSession;
@property (nonatomic, strong) AVCaptureDevice   *cameraCaptureDevice;

@property (nonatomic, strong) AVCaptureOutput   *cameraCaptureOutput;
@property (nonatomic, strong) AVCaptureOutput   *microphoneCaptureOutput;

@property (nonatomic, assign) BOOL  isRunning;

@property (strong, nonatomic) UIButton *actionButton;

@property (nonatomic, assign) BOOL audioOnly;

- (instancetype)initWithKey:(NSString *)userOrOfficeName
                withQuality:(NSInteger) qualityNum
           withAudioQualiyt:(NSInteger) audioQualityNum;

@end

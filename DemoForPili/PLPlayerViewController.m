//
//  PLPlayerViewController.m
//  PLPlayerKitDemo
//
//  Created by 0dayZh on 15/10/19.
//  Copyright © 2015年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "PLPlayerViewController.h"
#import <PLPlayerKit/PLPlayerKit.h>

static NSString *status[] = {
    @"PLPlayerStatusUnknow",
    @"PLPlayerStatusPreparing",
    @"PLPlayerStatusReady",
    @"PLPlayerStatusCaching",
    @"PLPlayerStatusPlaying",
    @"PLPlayerStatusPaused",
    @"PLPlayerStatusStopped",
    @"PLPlayerStatusError"
};

@interface PLPlayerViewController ()
<
PLPlayerDelegate,
UITextViewDelegate
>
@property (nonatomic, strong) PLPlayer  *player;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation PLPlayerViewController

- (instancetype)initWithURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        self.URL = URL;
    }
    
    return self;
}

- (void)dealloc {
    self.player = nil;
}

#pragma mark - <UITextViewDelegate>

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    return YES;
}

- (void)tap:(id)sender {
    [self.view endEditing:YES];
}

- (void)setupUI {
    self.title = @"直播";
    if (self.player.status != PLPlayerStatusError) {
        // add player view
        UIView *playerView = self.player.playerView;
        if (!playerView.superview) {
            playerView.contentMode = UIViewContentModeScaleAspectFit;
            playerView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
            [self.view addSubview:playerView];
            
//            // test input
//            UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(15, 80, CGRectGetWidth(self.view.bounds) - 30, 150)];
//            textView.delegate = self;
//            textView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
//            textView.textColor = [UIColor colorWithWhite:1 alpha:0.8];
//            textView.text = @"我是 TextView";
//            [self.view addSubview:textView];
//            
//            // button
//            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//            button.frame = CGRectMake(15, 400, 320, 44);
//            [button setTitle:@"Jump to safari" forState:UIControlStateNormal];
//            [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
//            [self.view addSubview:button];
//            
//            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
//            [self.view addGestureRecognizer:tap];
        }
    }
    
}

- (void)startPlayer {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.isViewLoaded) {
            [self addActivityIndicatorView];
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            [self.player play];
        }
    });
}

- (void)buttonPressed:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.baidu.com"]];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    PLPlayerOption *option = [PLPlayerOption defaultOption];
    [option setOptionValue:@15 forKey:PLPlayerOptionKeyTimeoutIntervalForMediaPackets];

    self.player = [PLPlayer playerWithURL:self.URL option:option];
    self.player.delegate = self;
    
    [self setupUI];
    
    [self startPlayer];
    
    __weak typeof(self) wself = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        __strong typeof(wself) strongSelf = wself;
        if (strongSelf.player.isPlaying) {
            [strongSelf.player stop];
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        __strong typeof(wself) strongSelf = wself;
        [strongSelf startPlayer];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self addActivityIndicatorView];
    if (self.player.status != PLPlayerStatusError) {
        [self.player play];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.player.isPlaying) {
        [self.player stop];
    }
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [super viewWillDisappear:animated];
}

- (void)addActivityIndicatorView {
    if (self.activityIndicatorView) {
        return;
    }
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    [self.view addSubview:activityIndicatorView];
    [activityIndicatorView stopAnimating];
    
    self.activityIndicatorView = activityIndicatorView;
}

#pragma mark -

//- (void)tap:(UITapGestureRecognizer *)tap {
//    self.player.isPlaying ? [self.player pause] : [self.player resume];
//}

#pragma mark - <PLPlayerDelegate>

- (void)player:(nonnull PLPlayer *)player statusDidChange:(PLPlayerStatus)state {
    if (PLPlayerStatusCaching == state) {
        [self.activityIndicatorView startAnimating];
    } else {
        [self.activityIndicatorView stopAnimating];
    }
    NSLog(@"%@", status[state]);
}

- (void)player:(nonnull PLPlayer *)player stoppedWithError:(nullable NSError *)error {
    [self.activityIndicatorView stopAnimating];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof(self) wself = self;
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *action) {
                                                           __strong typeof(wself) strongSelf = wself;
                                                           [strongSelf.navigationController performSelectorOnMainThread:@selector(popViewControllerAnimated:) withObject:@(YES) waitUntilDone:NO];
                                                       }];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    NSLog(@"%@", error);
}

@end
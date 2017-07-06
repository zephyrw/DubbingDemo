//
//  ViewController.m
//  ZYAudioRecordDemo
//
//  Created by wpsd on 2017/6/30.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "ZYViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "JC_MoviewAMusic.h"
#import "SVProgressHUD.h"
#import "EZAudio.h"
#import "UIView+Frame.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

@interface ZYViewController ()<EZMicrophoneDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) NSURL *recordURL;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *finishBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) NSURL *noAudioTrackVideoURL;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (weak, nonatomic) IBOutlet EZAudioPlotGL *currentAudioPlot;
@property (strong, nonatomic) EZAudioPlot *audioPlot;
@property (strong, nonatomic) UIView *plotContainerView;
@property (strong, nonatomic) UIView *plotBgView;
@property (strong, nonatomic) EZAudioFile *audioFile;
@property (strong, nonatomic) EZMicrophone *microphone;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (assign, nonatomic) int currentSeconds;
@property (strong, nonatomic) UIScrollView *scrollView;

@end

@implementation ZYViewController

- (NSURL *)recordURL {
    if (!_recordURL) {
        NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"myRecord.m4a"];
        _recordURL = [NSURL fileURLWithPath:filePath];
    }
    return _recordURL;
}

- (NSURL *)videoURL {
    if (!_videoURL) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"myVideo" ofType:@"mp4"];
        _videoURL = [NSURL fileURLWithPath:path];
    }
    return _videoURL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareForAudioPlot];
    [self removeAudioTrack];
    
}

- (void)prepareForAudioPlot {
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        NSLog(@"Error setting up audio session category: %@", error.localizedDescription);
    }
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"Error setting up audio session active: %@", error.localizedDescription);
    }
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.currentAudioPlot.frame) + 80, SCREEN_WIDTH, 70)];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.bounces = NO;
    scrollView.backgroundColor = [UIColor colorWithRed: 0.816 green: 0.349 blue: 0.255 alpha: 1];
    scrollView.delegate = self;
    self.scrollView = scrollView;
    [self.view addSubview:scrollView];
    
    self.audioPlot = [[EZAudioPlot alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2, 0, SCREEN_WIDTH, 70)];
    self.audioPlot.layer.anchorPoint = CGPointMake(0, 0.5);
    self.audioPlot.layer.position = CGPointMake(SCREEN_WIDTH / 2, 35);
    
    self.plotBgView = [[UIView alloc] initWithFrame:self.audioPlot.frame];;
    self.plotBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15];
    
    self.plotContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.audioPlot.frame.size.width + SCREEN_WIDTH, 70)];
    scrollView.contentSize = self.plotContainerView.frame.size;
    self.plotContainerView.backgroundColor = [UIColor clearColor];
    [self.plotContainerView addSubview:self.plotBgView];
    [self.plotContainerView addSubview:self.audioPlot];
    [scrollView addSubview:self.plotContainerView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2, scrollView.origin.y, 1, 70)];
    lineView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:lineView];
    
    self.audioPlot.backgroundColor = [UIColor clearColor];
    self.audioPlot.color           = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    self.audioPlot.plotType        = EZPlotTypeBuffer;
    self.audioPlot.shouldFill      = YES;
    self.audioPlot.shouldMirror    = YES;
    
    self.currentAudioPlot.backgroundColor = [UIColor colorWithRed:0.569 green:0.82 blue:0.478 alpha:1.0];
    self.currentAudioPlot.color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    self.currentAudioPlot.plotType = EZPlotTypeRolling;
    self.currentAudioPlot.shouldFill      = YES;
    self.currentAudioPlot.shouldMirror    = YES;
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
    
}

- (void)removeAudioTrack {
    
    [SVProgressHUD showWithStatus:@"正在准备视频，请稍候..."];
    [JC_MoviewAMusic movieFliePaths:@[self.videoURL] musicPath:nil success:^(NSURL * _Nullable successPath){
        self.noAudioTrackVideoURL = successPath;
        [SVProgressHUD showSuccessWithStatus:@"视频准备完毕"];
        NSLog(@"successPath: %@", successPath);
    } failure:^(NSString * _Nullable errorMsg){
        [SVProgressHUD showErrorWithStatus:errorMsg];
        NSLog(@"errorMsg: %@", errorMsg);
    }];
    
}

#pragma mark - Actions

- (IBAction)mixedVideoPlayBtnClick:(UIButton *)sender {
    
    [self setupPlayerWithVideoURL:self.videoURL];
    [self.player play];
    
}

- (IBAction)mixBtnClick:(UIButton *)sender {
    
    if (self.audioRecorder.isRecording) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"现在是录音状态，请完成录音后再合成" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alertView show];
        return;
    }
    sender.selected = YES;
    [SVProgressHUD showWithStatus:@"正在合成中..."];
    [JC_MoviewAMusic movieFliePaths:@[self.videoURL] musicPath:self.recordURL success:^(NSURL * _Nullable successPath) {
        self.videoURL = successPath;
        sender.selected = NO;
        [SVProgressHUD showSuccessWithStatus:@"合成成功！"];
    } failure:^(NSString * _Nullable errorMsg) {
        [SVProgressHUD showErrorWithStatus:@"合成失败"];
        NSLog(@"%@", errorMsg);
        sender.selected = NO;
    }];
    
}

- (IBAction)recordBtnClick:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        if (!self.audioRecorder) {
            [self setupPlayerWithVideoURL:self.noAudioTrackVideoURL];
            [self setupAudioRecorder];
            [self.currentAudioPlot clear];
            self.currentSeconds = 0;
            NSLog(@"start record");
        }
        if ([self.audioRecorder prepareToRecord] == YES){
            self.audioRecorder.meteringEnabled = YES;
            [self.audioRecorder record];
            [self.player play];
        }else {
            NSLog(@"FlyElephant--初始化录音失败");
        }
        [self countTime];
        [self.microphone startFetchingAudio];
        return;
    }
    [self.player pause];
    [self.audioRecorder pause];
    [self.microphone stopFetchingAudio];
}

- (IBAction)finishBtnClick:(UIButton *)sender {
    self.recordBtn.selected = NO;
    self.audioRecorder = nil;
    [self.player pause];
    NSLog(@"finish record");
    [self.audioRecorder stop];
    [self.microphone stopFetchingAudio];
    [self openFileWithFilePathURL:self.recordURL];
}

- (IBAction)playBtnClick:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        NSLog(@"play record file");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        NSError *error;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordURL error:&error];
        if (error) {
            NSLog(@"Failed to create audio player: %@", error);
        }
        self.audioPlayer.numberOfLoops = 0;
        [self.audioPlayer play];
        return;
    }
    [self.audioPlayer stop];
}

#pragma mark - Help method

- (void)countTime {
    
    int min = 0;
    int sec = 0;
    if (self.currentSeconds >= 60) {
        min = self.currentSeconds / 60;
        sec = self.currentSeconds % 60;
    } else {
        min = 0;
        sec = self.currentSeconds;
    }
    self.currentSeconds += 1;
    self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d",min, sec];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.recordBtn.isSelected) {
            [self countTime];
        }
    });
    
}

- (void)setupAudioRecorder {
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        NSLog(@"Failed to set category: %@", error);
    }
    NSError *recorderError = nil;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:self.recordURL settings:[self audioRecordingSettings] error:&recorderError];
    if (recorderError) {
        NSLog(@"Failed to create recorder: %@", recorderError);
    }
    self.audioRecorder.meteringEnabled = YES;
    
}

- (NSDictionary *)audioRecordingSettings{
    
    NSDictionary *result = nil;
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleLossless] forKey:AVFormatIDKey];
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    [recordSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    
    result = [NSDictionary dictionaryWithDictionary:recordSetting];
    return result;
}

- (void)setupPlayerWithVideoURL:(NSURL *)videoURL {
    
    self.playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    if (self.playerLayer) {
        [self.playerLayer removeFromSuperlayer];
    }else {
        [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.frame = CGRectMake(0, 100, SCREEN_WIDTH, SCREEN_WIDTH * 9 / 16);
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if (status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
        }else if (status == AVPlayerStatusFailed) {
            NSLog(@"播放失败");
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        CMTimeRange timeRange = [[[change objectForKey:@"new"] lastObject] CMTimeRangeValue];
        CGFloat startTime = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        CGFloat completeSeconds = startTime + durationSeconds;
        CGFloat totalDuration = CMTimeGetSeconds(playerItem.duration);
        CGFloat percent = completeSeconds / totalDuration;
        NSLog(@"缓冲进度：%.2f", percent);
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        NSLog(@"playbackBufferEmpty");
    }
    if ([keyPath isEqualToString:@"rate"]) {
        NSLog(@"rate: %f", [[change objectForKey:@"new"] floatValue]);
        if ([[change objectForKey:@"new"] floatValue] == 0.0) {
            //            self.playBtn.selected = NO;
        }else {
            //            self.playBtn.selected = YES;
        }
    }
}

- (void)openFileWithFilePathURL:(NSURL *)filePathURL
{
    self.scrollView.contentOffset = CGPointMake(0, 0);
    self.audioFile = [EZAudioFile audioFileWithURL:filePathURL];
    CGFloat scale = self.audioFile.duration / 11.0;
    self.plotBgView.width = SCREEN_WIDTH * scale;
    self.audioPlot.transform = CGAffineTransformMakeScale(scale, scale < 1 ? scale : 1);
    self.plotContainerView.width = self.audioPlot.width + SCREEN_WIDTH;
    self.scrollView.contentSize = self.plotContainerView.frame.size;
    __weak typeof (self) weakSelf = self;
    [self.audioFile getWaveformDataWithCompletionBlock:^(float **waveformData,
                                                         int length)
     {
         [weakSelf.audioPlot updateBuffer:waveformData[0]
                           withBufferSize:length];
     }];
}

#pragma mark - EZMicrophoneDelegate

- (void)microphone:(EZMicrophone *)microphone hasAudioReceived:(float **)buffer withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels {
    
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.currentAudioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat newTime = scrollView.contentOffset.x / SCREEN_WIDTH * 11;
    if (newTime <= self.playerItem.duration.value / self.playerItem.duration.timescale) {
    [self.player seekToTime:CMTimeMake(newTime, 1)];
    }
    
}

@end


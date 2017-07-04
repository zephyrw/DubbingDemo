//
//  ViewController.m
//  ZYAudioRecordDemo
//
//  Created by wpsd on 2017/6/30.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "JC_MoviewAMusic.h"
#import "SVProgressHUD.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

@interface ViewController ()

@property (strong, nonatomic) NSURL *recordURL;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *finishBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@end

@implementation ViewController

- (NSURL *)recordURL {
    if (!_recordURL) {
        NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"myRecord.caf"];
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
    
    [SVProgressHUD showWithStatus:@"正在准备视频，请稍候..."];
    [JC_MoviewAMusic movieFliePaths:@[self.videoURL] musicPath:nil success:^(NSURL * _Nullable successPath){
        self.videoURL = successPath;
        [SVProgressHUD showSuccessWithStatus:@"视频准备完毕"];
        NSLog(@"successPath: %@", successPath);
    } failure:^(NSString * _Nullable errorMsg){
        [SVProgressHUD showErrorWithStatus:errorMsg];
        NSLog(@"errorMsg: %@", errorMsg);
    }];
    
}

- (void)setupPlayer {
    
    if (self.playerLayer) {
        [self.playerLayer removeFromSuperlayer];
    }
    self.playerItem = [[AVPlayerItem alloc] initWithURL:self.videoURL];
    self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.view.layer insertSublayer:self.playerLayer atIndex:0];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.frame = CGRectMake(0, 100, SCREEN_WIDTH, SCREEN_WIDTH * 9 / 16);
    
}
- (IBAction)mixedVideoPlayBtnClick:(UIButton *)sender {
    
    [self setupPlayer];
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
            [self setupPlayer];
            [self setupAudioRecorder];
            NSLog(@"start record");
        }
        if ([self.audioRecorder prepareToRecord] == YES){
            self.audioRecorder.meteringEnabled = YES;
            [self.audioRecorder record];
            [self.player play];
        }else {
            NSLog(@"FlyElephant--初始化录音失败");
        }
        return;
    }
    [self.player pause];
    [self.audioRecorder pause];
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

- (IBAction)finishBtnClick:(UIButton *)sender {
    self.recordBtn.selected = NO;
    self.audioRecorder = nil;
    [self.player pause];
    NSLog(@"finish record");
    [self.audioRecorder stop];
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

@end

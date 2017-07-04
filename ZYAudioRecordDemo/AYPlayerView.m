//
//  AYPlayer.m
//  AYPlayer
//
//  Created by wpsd on 2016/11/22.
//  Copyright © 2016年 wpsd. All rights reserved.
//

#import "AYPlayerView.h"
#import <AVFoundation/AVFoundation.h>

#define kTimeLableZreo @"00:00/00:00"

@interface AYPlayerView ()

@property (strong, nonatomic) UILabel *timeLabel;
@property (strong, nonatomic) UISlider *timeProgress;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UIButton *playBtn;
@property (strong, nonatomic) UIView *bottomControlView;
@property (assign, nonatomic) CGRect orginFrame;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIButton *downloadBtn;

@end

@implementation AYPlayerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.orginFrame = frame;
        [self setUpSubviews];
    }
    return self;
}

- (void)setUpSubviews {
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    self.backgroundColor = [UIColor blackColor];
//    self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    UIActivityIndicatorView *activityIndicator = [UIActivityIndicatorView new];
    activityIndicator.frame = CGRectMake(0, 0, 40, 40);
    activityIndicator.center = self.center;
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.activityIndicator = activityIndicator;
    [self addSubview:activityIndicator];
    
    //集合底部控件的view，所有底部控件全在该view上
    CGFloat bottomH = 40;
    UIView *bottomControlView = [[UIView alloc] initWithFrame:CGRectMake(0, height - bottomH, width, bottomH)];
    bottomControlView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    bottomControlView.alpha = 0;
    self.bottomControlView = bottomControlView;
    [self addSubview:bottomControlView];

    //添加播放器控件
    CGFloat timeProgressX = 40;
    UISlider *timeProgress = [[UISlider alloc] initWithFrame:CGRectMake(timeProgressX, 0, width - timeProgressX * 2, bottomH - 10)];
    timeProgress.minimumValue = 0;
    timeProgress.maximumValue = 1;
    [timeProgress addTarget:self action:@selector(sliderChange:) forControlEvents:UIControlEventValueChanged];
    [timeProgress addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [timeProgress addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    timeProgress.minimumTrackTintColor = [UIColor whiteColor];
    timeProgress.maximumTrackTintColor = [UIColor grayColor];
    
    [timeProgress setThumbImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
    [timeProgress setThumbImage:[UIImage imageNamed:@"Player_slider"] forState:UIControlStateHighlighted];
    timeProgress.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.timeProgress = timeProgress;
    
    [bottomControlView addSubview:timeProgress];

    //添加播放按钮
    CGFloat playBtnX = 12;
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playBtn.frame = CGRectMake(playBtnX, 6, 18, 20);
    [playBtn setImage:[UIImage imageNamed:@"Player_play"] forState:UIControlStateNormal];
    [playBtn setImage:[UIImage imageNamed:@"Player_pause"] forState:UIControlStateSelected];
    [playBtn addTarget:self action:@selector(playOrPause:) forControlEvents:UIControlEventTouchUpInside];
    playBtn.selected = NO;
    self.playBtn = playBtn;
    [bottomControlView addSubview:playBtn];

    //添加全屏按钮
    CGFloat fullWH = 15;
    UIButton *fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    fullScreenBtn.frame = CGRectMake(width - playBtnX - fullWH, 8, fullWH, fullWH);
    [fullScreenBtn setImage:[UIImage imageNamed:@"Player_fullscreen"] forState:UIControlStateNormal];
    [fullScreenBtn setImage:[UIImage imageNamed:@"Player_shrinkscreen"] forState:UIControlStateSelected];
    [fullScreenBtn addTarget:self action:@selector(fullScreenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    fullScreenBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [bottomControlView addSubview: fullScreenBtn];
    
    //添加时间label
    CGFloat timeLabelY = timeProgress.center.y;
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeProgressX, timeLabelY, 200, 21)];
    timeLabel.text = kTimeLableZreo;
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.font = [UIFont systemFontOfSize:10];
    self.timeLabel = timeLabel;
    [bottomControlView addSubview:timeLabel];
    
    //界面
    UIButton *downLoadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    downLoadBtn.frame = CGRectMake(width - 20 - 40, (height - 49) / 2, 40, 49);
    [downLoadBtn setImage:[UIImage imageNamed:@"Player_download"] forState:UIControlStateNormal];
    [downLoadBtn setImage:[UIImage imageNamed:@"Player_not_download"] forState:UIControlStateSelected];
    [downLoadBtn addTarget:self action:@selector(downLoadBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    downLoadBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin;
    downLoadBtn.alpha = 0;
    self.downloadBtn = downLoadBtn;
    [self addSubview:downLoadBtn];
    
}

- (void)setupAVPlayerWithURL:(NSURL *)url {
    self.playerItem = [AVPlayerItem playerItemWithURL:url];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.bounds;
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    [self.activityIndicator startAnimating];
    [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if (status == AVPlayerStatusReadyToPlay) {
            [self listenToTimeChange];
            [self.activityIndicator stopAnimating];
            [self.player play];
            //添加手势
            UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
            [singleTapGestureRecognizer setNumberOfTapsRequired:1];
            [self addGestureRecognizer:singleTapGestureRecognizer];
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
        if ([[change objectForKey:@"new"] floatValue] == 0.0) {
            self.playBtn.selected = NO;
        }else {
            self.playBtn.selected = YES;
        }
    }
}

- (void)orientationDidChange:(NSNotification *)noti {
    __weak typeof(self) weakSelf = self;
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight || [UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
        weakSelf.frame = CGRectMake(0, 0, kMainWidth, kMainHeight);
        weakSelf.playerLayer.frame = weakSelf.bounds;
    }else {
        weakSelf.frame = self.orginFrame;
        weakSelf.playerLayer.frame = weakSelf.bounds;
    }
}

- (void)startPlay {
    [self.player play];
}

- (void)listenToTimeChange {
    if (self.timer) { self.timer = nil; }
    __weak typeof(self) weakSelf = self;
    self.timer = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat playTime = weakSelf.player.currentTime.value / weakSelf.player.currentTime.timescale;
        CGFloat totalTime = self.playerItem.duration.value / self.playerItem.duration.timescale;
        CGFloat percent = playTime / totalTime;
        weakSelf.timeLabel.text = [NSString stringWithFormat:@"%@/%@",[weakSelf changeTime:playTime], [weakSelf changeTime:totalTime]];
        weakSelf.timeProgress.value = percent;
    }];
}

- (NSString *)changeTime:(CGFloat)time {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (time > 3600) {
        formatter.dateFormat = @"HH:mm:ss";
    }else {
        formatter.dateFormat = @"mm:ss";
    }
    return [formatter stringFromDate:date];
}

#pragma mark - Actions

- (void)playOrPause:(UIButton *)sender {
    if (sender.isSelected) {
        [self.player pause];
    }else {
        [self.player play];
    }
}

- (void)sliderTouchDown:(UISlider *)sender {
    [self.player pause];
}

- (void)sliderChange:(UISlider *)sender {
    CGFloat totalTime = self.playerItem.duration.value / self.playerItem.duration.timescale;
    CMTime newTime = CMTimeMake(totalTime * sender.value, 1);
    [self.player seekToTime:newTime];
    self.bottomControlView.alpha = 1;
}

- (void)sliderTouchUp:(UISlider *)sender {
    [self.player play];
    [self hideControlWithDelayTime:3.0];
}

- (void)fullScreenBtnClick:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            [[UIDevice currentDevice] performSelector:@selector(setOrientation:) withObject:@(UIDeviceOrientationLandscapeLeft) afterDelay:0];
        }
    } else {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
//            [[UIDevice currentDevice] performSelector:@selector(setOrientation:) withObject:@(UIDeviceOrientationPortrait) afterDelay:0];
            [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortrait) forKey:@"orientation"];
        }
    }
}

- (void)downLoadBtnPress:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    sender.userInteractionEnabled = NO;
}

- (void)singleTap:(UITapGestureRecognizer *)tapGes {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.2f animations:^{
        weakSelf.bottomControlView.alpha = 1;
        weakSelf.downloadBtn.alpha = 1;
    } completion:^(BOOL finished) {
        [weakSelf hideControlWithDelayTime:3.0];
    }];
}

- (void)hideControlWithDelayTime:(NSTimeInterval)delay {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.bottomControlView.alpha = 0;
            weakSelf.downloadBtn.alpha = 0;
        }];
    });
}

- (void)playFinished:(NSNotification *)noti {
    NSLog(@"%s", __func__);
}

- (void)releasePlayerView {
    [self.player removeTimeObserver:_timer];
    self.timer = nil;
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];
    self.player = nil;
    self.playerItem = nil;
    [self removeAllGestures];
    [self hideControlWithDelayTime:0];
}


@end

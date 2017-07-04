//
//  ZYRecordDraftView.m
//  ZYAudioRecordDemo
//
//  Created by wpsd on 2017/7/4.
//  Copyright © 2017年 wpsd. All rights reserved.
//

#import "ZYRecordDraftView.h"
#import <AVFoundation/AVFoundation.h>

@interface ZYRecordDraftView ()

@property (strong, nonatomic) NSURL *recordURL;
@property (strong, nonatomic) NSArray *filerSamples;
@property (strong, nonatomic) NSMutableArray *itemArray;
@property (strong, nonatomic) UIColor *itemColor;
@property (strong, nonatomic) NSMutableArray *levelArray;

@end

@implementation ZYRecordDraftView

- (void)setupWithRect:(CGRect)rect recordURL:(NSURL *)recordURL {
    
    self.recordURL = recordURL;
    self.itemArray = [NSMutableArray new];
    
    NSArray *filerSamples = [self cutAudioData:self.bounds.size];//得到绘制数据
    self.filerSamples = filerSamples;
    
    self.itemColor = [UIColor colorWithRed:241/255.f green:60/255.f blue:57/255.f alpha:1.0];
    
    self.levelArray = [[NSMutableArray alloc] init];
    
    // 计算音轨数组的平均值
    double avg = 0;
    int sum = 0;
    for (int i = 0; i < self.filerSamples.count; i++) {
        sum += [self.filerSamples[i] intValue];
    }
    avg = sum / self.filerSamples.count;
    
    for (int i = 0 ; i < self.filerSamples.count ; i++){
        
        // 计算每组数据与平均值的差值
        int Xi = [self.filerSamples[i] intValue];
        CGFloat scale = (Xi - avg)/avg;     // 绘制线条的缩放比例
        
        int baseH = 0;      // 长度基数,   线条长度范围: baseH + 10 ~ baseH + 100
        
        if (scale <= -0.4) {
            [self.levelArray addObject:@(baseH + 10)];
        }else if (scale > -0.4 && scale <= -0.3) {
            [self.levelArray addObject:@(baseH + 20)];
        }else if (scale > -0.3 && scale <= -0.2) {
            [self.levelArray addObject:@(baseH + 30)];
        }else if (scale > -0.2 && scale <= -0.1) {
            [self.levelArray addObject:@(baseH + 40)];
        }else if (scale > -0.1 && scale <= 0) {
            [self.levelArray addObject:@(baseH + 50)];
        }else if (scale > 0 && scale <= 0.1) {
            [self.levelArray addObject:@(baseH + 60)];
        } else if (scale > 0.1 && scale <= 0.2) {
            [self.levelArray addObject:@(baseH + 70)];
        } else if (scale > 0.2 && scale <= 0.3) {
            [self.levelArray addObject:@(baseH + 80)];
        } else if (scale > 0.3 && scale <= 0.4) {
            [self.levelArray addObject:@(baseH + 90)];
        } else if (scale > 0.4) {
            [self.levelArray addObject:@(baseH + 100)];
        }
        
        CAShapeLayer *itemline = [CAShapeLayer layer];
        itemline.lineCap       = kCALineCapButt;
        itemline.lineJoin      = kCALineJoinRound;
        itemline.fillColor     = [[UIColor clearColor] CGColor];
        [itemline setLineWidth:rect.size.width * 0.4 / self.filerSamples.count];
        itemline.strokeColor   = [self.itemColor CGColor];
        
        [self.layer addSublayer:itemline];
        [self.itemArray addObject:itemline];
    }
    [self updateItemsWithRect:rect];
}

- (void)updateItemsWithRect:(CGRect)rect
{
    UIGraphicsBeginImageContext(self.frame.size);
    
    CGFloat x = rect.size.width * 0.8 / (self.filerSamples.count);  // x：表示两个线条的间隔
    CGFloat z = rect.size.width * 0.2 / self.filerSamples.count;
    CGFloat y = rect.size.width * 0.09 - z;  // y：表示线条的起始位置
    
    for (int i=0; i < (self.itemArray.count); i++) {
        
        UIBezierPath *itemLinePath = [UIBezierPath bezierPath];
        y += x;
        CGPoint point = CGPointMake(y, rect.size.height / 2 + ([[self.levelArray objectAtIndex:i] intValue] + 1) * z / 2);
        [itemLinePath moveToPoint:point];
        CGPoint toPoint = CGPointMake(y, rect.size.height / 2 - ([[self.levelArray objectAtIndex:i] intValue] + 1) * z / 2);
        [itemLinePath addLineToPoint:toPoint];
        
        CAShapeLayer *itemLine = [self.itemArray objectAtIndex:i];
        itemLine.path = [itemLinePath CGPath];
        
    }
    UIGraphicsEndImageContext();
}

//缩减音频 (size为将要绘制波纹的view的尺寸，不需要请忽略)
- (NSArray *)cutAudioData:(CGSize)size {
    NSMutableArray *filteredSamplesMA = [[NSMutableArray alloc]init];
    NSData *data = [self getRecorderDataFromURL:self.recordURL];
    NSUInteger sampleCount = data.length / sizeof(SInt16);//计算所有数据个数
    NSUInteger binSize = sampleCount / (size.width * 0.1); //将数据分割为一个个小包
    
    SInt16 *bytes = (SInt16 *)data.bytes; //总的数据个数
    SInt16 maxSample = 0; //sint16两个字节的空间
    //以binSize为一个样本。每个样本中取一个最大数。也就是在固定范围取一个最大的数据保存，达到缩减目的
    for (NSUInteger i= 0; i < sampleCount; i += binSize) {
        //在sampleCount（所有数据）个数据中抽样，抽样方法为在binSize个数据为一个样本，在样本中选取一个数据
        SInt16 sampleBin[binSize];
        for (NSUInteger j = 0; j < binSize; j++) {//先将每次抽样样本的binSize个数据遍历出来
            
            sampleBin[j] = CFSwapInt16LittleToHost(bytes[i + j]);
            
        }
        //选取样本数据中最大的一个数据
        SInt16 value = [self maxValueInArray:sampleBin ofSize:binSize];
        //保存数据
        [filteredSamplesMA addObject:@(value)];
        //将所有数据中的最大数据保存，作为一个参考。可以根据情况对所有数据进行“缩放”
        if (value > maxSample) {
            maxSample = value;
        }
    }
    //计算比例因子
    CGFloat scaleFactor = (size.height * 0.5)/maxSample;
    //对所有数据进行“缩放”
    for (NSUInteger i = 0; i < filteredSamplesMA.count; i++) {
        
        filteredSamplesMA[i] = @([filteredSamplesMA[i] integerValue] * scaleFactor);
    }
    
    return filteredSamplesMA;
}

- (NSData *)getRecorderDataFromURL:(NSURL *)recordURL {
    
    AVAsset *asset = [AVAsset assetWithURL:recordURL]; //获取文件
    AVAssetTrack *track = nil;
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count) {
        track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];  //从媒体中得到声音轨道
    } else {
        NSLog(@"获取音频失败");
        return nil;
    }
    NSMutableData *data = [[NSMutableData alloc]init]; //用于保存音频数据
    
    //读取配置
    NSDictionary *dic = @{AVFormatIDKey :@(kAudioFormatLinearPCM),
                          AVLinearPCMIsBigEndianKey:@NO,    // 小端存储
                          AVLinearPCMIsFloatKey:@NO,    //采样信号是整数
                          AVLinearPCMBitDepthKey :@(16)  //采样位数默认 16
                          };
    
    
    NSError *error;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error]; //创建读取
    if (!reader) {
        NSLog(@"%@",[error localizedDescription]);
    }
    //读取输出，在相应的轨道上输出对应格式的数据
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc]initWithTrack:track outputSettings:dic];
    
    //赋给读取并开启读取
    [reader addOutput:output];
    [reader startReading];
    
    //读取是一个持续的过程，每次只读取后面对应的大小的数据
    while (reader.status == AVAssetReaderStatusReading) {
        
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer]; //读取到数据
        if (sampleBuffer) {
            CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(sampleBuffer);//取出数据
            //返回一个大小，size_t针对不同的平台有不同的实现，扩展性更好
            size_t length = CMBlockBufferGetDataLength(blockBUfferRef);
            
            SInt16 sampleBytes[length];
            CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes); //将数据放入数组
            [data appendBytes:sampleBytes length:length]; //将数据附加到data中
            CMSampleBufferInvalidate(sampleBuffer);//销毁
            CFRelease(sampleBuffer); //释放
        }
    }
    if (reader.status == AVAssetReaderStatusCompleted) {
        // 读取结束...
        return data;
    }else{
        NSLog(@"获取音频数据失败");
        return nil;
    }
    
}

//比较大小的方法，返回最大值
- (SInt16)maxValueInArray:(SInt16[])values ofSize:(NSUInteger)size {
    SInt16 maxvalue = 0;
    for (int i = 0; i < size; i++) {
        
        if (abs(values[i] > maxvalue)) {
            maxvalue = abs(values[i]);
        }
    }
    return maxvalue;
}


@end

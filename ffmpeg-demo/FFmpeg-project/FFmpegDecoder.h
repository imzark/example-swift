//
//  FFmpegDecoder.h
//  FFmpeg-project
//
//  Created by huizai on 2017/9/14.
//  Copyright © 2017年 huizai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "avcodec.h"
#import "swscale.h"
#import "avformat.h"
#import "swresample.h"
#import "samplefmt.h"
#import "YUV_GL_DATA.h"


@interface FFmpegDecoder : NSObject
//总时长
@property (nonatomic,assign)int  totalMs;
//音频播放时间
@property (nonatomic,assign)int  aFps;
//视频播放时间
@property (nonatomic,assign)int  vFps;
//视频流索引
@property (nonatomic,assign)int  videoStreamIndex;
//音频流索引
@property (nonatomic,assign)int  audioStreamIndex;
@property (nonatomic,assign)int  sampleRate;
@property (nonatomic,assign)int  sampleSize;
@property (nonatomic,assign)int  channel;
//音频贞数据的长度
@property (nonatomic,assign)int  pcmDataLength;


#pragma mark - 接口
- (BOOL)OpenUrl:(const char*)path;
- (void)Read:(AVPacket*)pkt;
- (void)Decode:(AVPacket*)pkt;
- (H264YUV_Frame)YuvToGlData:(H264YUV_Frame)yuvFrame;
- (BOOL)ToRGB:(char*)outBuf andWithOutHeight:(int)outHeight andWithOutWidth:(int)outWidth;
- (UIImage*)ToImage:(char*)dataBuf andWithOutHeight:(int)outHeight andWithOutWidth:(int)outWidth;
//音频重采样
- (int)ToPCM:(char*)dataBuf;
//获取错误信息
- (NSString*)GetError;
- (void)Close;

@end

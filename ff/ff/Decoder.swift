//
//  Decoder.swift
//  ff
//
//  Created by harry on 2019/8/13.
//  Copyright © 2019 harry. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox


public struct VideoFrame {
  var width:Int32 = 0
  var height:Int32 = 0
  var linesize: Int32 = 0
  var frame: AVFrame? = nil
  var position:Double = 0
  var duration:Double = 0
  var buffer:CVPixelBuffer? = nil
}

var hw_pix_fmt: AVPixelFormat? = nil
var hw_device_ctx: UnsafeMutablePointer<AVBufferRef>? = nil

public func get_hw_format(ctx: UnsafeMutablePointer<AVCodecContext>?, pix_fmts: UnsafePointer<AVPixelFormat>?) -> AVPixelFormat {
  var p: AVPixelFormat = AV_PIX_FMT_NONE
  if pix_fmts != nil{
    p = pix_fmts!.pointee
    while p.rawValue != -1 {
      if p == hw_pix_fmt {
        return p
      }
      p.rawValue += 1
    }
  }
  print("Failed to get HW surface format. p: \(p) \n")
  return p
}

class Decoder {
  static let shared = Decoder()
  // video 流索引
  var videoStreamIndex:Int32 = -1
  var audioStreamIndex:Int32 = -1
  // video 流
  var videoStream: UnsafeMutablePointer<AVStream>? = nil
  var audioStream: UnsafeMutablePointer<AVStream>? = nil
  // frame
  var videoFrame: UnsafeMutablePointer<AVFrame>? = nil
  var audioFrame: UnsafeMutablePointer<AVFrame>? = nil
  // 上下文
  var formatContext: UnsafeMutablePointer<AVFormatContext>? = nil
  // 解码器上下文
  var videoCodecCtx: UnsafeMutablePointer<AVCodecContext>? = nil
  var audioCodecCtx: UnsafeMutablePointer<AVCodecContext>? = nil
  //
  var videoDecoder: UnsafeMutablePointer<AVCodec>? = nil
  var audioDecoder: UnsafeMutablePointer<AVCodec>? = nil
  
  // 处理放回结果
  var ret:Int32 = 0
  
  var fps: CDouble = 0
  var videoTimeBase: CDouble = 0
  var isEOF = false
  var opened = false
  var type: AVHWDeviceType = av_hwdevice_find_type_by_name("videotoolbox") //MacOS和iOS可以固定写videotoolbox
  
  open func start(_ path: String?) -> Bool {
    avformat_network_init()
    
    let videoSourceURI = path?.cString(using: .utf8)
    
    if avformat_open_input(&formatContext, videoSourceURI, nil, nil) != 0 {
      print("Couldn't open file")
      if formatContext != nil {
        avformat_close_input(&formatContext)
      }
      return false
    }
    
    if avformat_find_stream_info(formatContext, nil) < 0 {
      print("Cannot find input stream information.\n")
      if formatContext != nil {
        avformat_close_input(&formatContext)
      }
      return false
    }
    
    /* find the video stream information */
    ret = av_find_best_stream(formatContext, AVMEDIA_TYPE_VIDEO, -1, -1, &videoDecoder, 0);
    if ret < 0 {
      print("Cannot find a video stream in the input file\n")
      return false;
    }
    videoStreamIndex = ret
    
    ret = av_find_best_stream(formatContext, AVMEDIA_TYPE_AUDIO, -1, -1, &audioDecoder, 0)
    if ret < 0 {
      print("Cannot find a audio stream in the input file\n")
      return false;
    }
    audioStreamIndex = ret
    
    var i:Int32 = 0
    while true {
      let config = avcodec_get_hw_config(videoDecoder, i)
      if config == nil {
        print("Decoder \(String(describing: videoDecoder?.pointee.name)) does not support device type \(String(describing: av_hwdevice_get_type_name(type))).\n")
      } else if ((config?.pointee.methods) != nil) && AV_CODEC_HW_CONFIG_METHOD_HW_DEVICE_CTX != 0 && config?.pointee.device_type == type {
        hw_pix_fmt = config?.pointee.pix_fmt
        break
      }
      i += 1
    }
    
    print("fmt: \(hw_pix_fmt); ios: \(AV_PIX_FMT_VIDEOTOOLBOX)")
    
    videoCodecCtx = avcodec_alloc_context3(videoDecoder)
    if videoCodecCtx == nil {
      return false
    }
    
    audioCodecCtx = avcodec_alloc_context3(audioDecoder)
    if audioCodecCtx == nil {
      return false
    }
    
    videoStream = formatContext?.pointee.streams![Int(videoStreamIndex)]
    audioStream = formatContext?.pointee.streams![Int(audioStreamIndex)]
    
    
    if (videoStream!.pointee.time_base.den >= 1) && (videoStream!.pointee.time_base.num >= 1) {
      videoTimeBase = av_q2d(videoStream!.pointee.time_base)
    } else if (videoCodecCtx!.pointee.time_base.den >= 1) && (videoCodecCtx!.pointee.time_base.num >= 1) {
      videoTimeBase = av_q2d(videoCodecCtx!.pointee.time_base)
    } else {
      videoTimeBase = 0.04
    }

    if (videoCodecCtx!.pointee.ticks_per_frame != 1) {
      print("WARNING: ticks_per_frame")
    }
    if (videoStream!.pointee.avg_frame_rate.den >= 1) && (videoStream!.pointee.avg_frame_rate.num >= 1) {
      fps = av_q2d(videoStream!.pointee.avg_frame_rate)
    } else if (videoStream!.pointee.r_frame_rate.den >= 1) && (videoStream!.pointee.r_frame_rate.num >= 1) {
      fps = av_q2d(videoStream!.pointee.r_frame_rate)
    } else {
      fps = 1 / self.videoTimeBase
    }
    
    ret = avcodec_parameters_to_context(videoCodecCtx, videoStream?.pointee.codecpar)
    if ret < 0 {
      return false
    }

    ret = avcodec_parameters_to_context(audioCodecCtx, audioStream?.pointee.codecpar)
    if ret < 0 {
      return false
    }
    
    videoCodecCtx?.pointee.get_format = get_hw_format
    if av_hwdevice_ctx_create(&hw_device_ctx, type, nil, nil, 0) < 0 {
      print("Failed to create specified HW device.\n")
      return false
    }
    videoCodecCtx?.pointee.hw_device_ctx = av_buffer_ref(hw_device_ctx)
    
    
    ret = avcodec_open2(videoCodecCtx, videoDecoder, nil)
    if ret < 0 {
      print("Failed to open codec for stream \(String(videoStreamIndex))\n");
      return false;
    }
    
    ret = avcodec_open2(audioCodecCtx, audioDecoder, nil)
    if ret < 0 {
      print("Failed to open codec for stream \(String(audioStreamIndex))\n");
      return false;
    }
    
    av_dump_format(formatContext, 0, videoSourceURI, 0)
    opened = true
    
    
    return true
  }
  
  open func decode(_ minDuaration: Double) -> [VideoFrame] {
    let packet = av_packet_alloc()
    var finished = false
    
    var decodedDuration = 0.0
    var videoResult:[VideoFrame] = []
    
    while !finished {
      ret = av_read_frame(formatContext, packet)
      if ret < 0 {
        isEOF = true
        break
      }
      
      if packet?.pointee.stream_index == audioStreamIndex {
      }
      
      if packet?.pointee.stream_index == videoStreamIndex {
        let (res , d) = decodeVideo(videoCodecCtx, packet)
        decodedDuration += d
        videoResult.append(contentsOf: res)
      }
      if decodedDuration > minDuaration {
        finished = true
      }
      av_packet_unref(packet)
    }
    return videoResult
  }
  
  private func decodeVideo(_ videoCodecCtx: UnsafeMutablePointer<AVCodecContext>?, _ packet: UnsafeMutablePointer<AVPacket>?) -> ([VideoFrame], Double){
    var frame:UnsafeMutablePointer<AVFrame>? = nil
    var sw_frame:UnsafeMutablePointer<AVFrame>? = nil
    var tmp_frame:UnsafeMutablePointer<AVFrame>? = nil
    
    var videoResult:[VideoFrame] = []
    var decodedDuration = 0.0
    
    var ret2:Int32 = avcodec_send_packet(videoCodecCtx, packet);
    if (ret2 < 0) {
      print("Error during decoding\n")
    }
    
    while ret2 >= 0 {
      frame = av_frame_alloc()
      sw_frame = av_frame_alloc()
      
      if frame == nil || sw_frame == nil {
        print("Can not alloc frame\n")
      }
      ret2 = avcodec_receive_frame(videoCodecCtx, frame)
      
      if ret2 < 0 {
        print("Error while decoding:\(ret2) \n")
        break
      }
      
      var v = VideoFrame()
      
      if hw_pix_fmt != nil && frame?.pointee.format == hw_pix_fmt!.rawValue {
        /* retrieve data from GPU to CPU */
        ret2 = av_hwframe_transfer_data(sw_frame, frame, 0)
        if ret2 < 0 {
          print("Error transferring the data to system memory\n")
        }
        tmp_frame = sw_frame;
      } else {
        tmp_frame = frame;
      }
      
      var duration = 0.0
      v.frame = tmp_frame?.pointee
      v.height = (videoCodecCtx?.pointee.height)!
      v.width = (videoCodecCtx?.pointee.width)!
      v.linesize = (tmp_frame?.pointee.linesize.0)!
      
      let frameDuration = av_frame_get_pkt_duration(tmp_frame)
      if frameDuration > 0 {
        duration = Double(frameDuration) * videoTimeBase
        duration += Double((tmp_frame?.pointee.repeat_pict)!) * videoTimeBase * 0.5
      } else {
        duration = 1.0 / fps
      }
      duration = 1.0 / fps
      
      v.duration = duration
      v.position = Double(av_frame_get_best_effort_timestamp(tmp_frame!)) * videoTimeBase
//      v.buffer = f2i(in: v)
      videoResult.append(v)
      decodedDuration += duration
    }
    av_frame_free(&frame)
    av_frame_free(&tmp_frame)
    av_frame_free(&sw_frame)
    //    av_frame_unref(frame)
    //    av_frame_unref(tmp_frame)
    //    av_frame_unref(sw_frame)
    return (videoResult, decodedDuration)
  }
}

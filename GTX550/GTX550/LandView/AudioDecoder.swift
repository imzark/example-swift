
import Foundation

class AudioDecoder {
  // video 流索引
  var audioStreamIndex:Int32 = -1
  // video 流
  var audioStream: UnsafeMutablePointer<AVStream>? = nil
  // frame
  var audioFrame: UnsafeMutablePointer<AVFrame>? = nil
  // 上下文
  var formatContext: UnsafeMutablePointer<AVFormatContext>? = nil
  // 解码器上下文
  var audioCodecCtx: UnsafeMutablePointer<AVCodecContext>? = nil
  //
  var audioDecoder: UnsafeMutablePointer<AVCodec>? = nil
  // 处理放回结果
  var ret:Int32 = 0
  // 时间
  var duration:Double = 0
  var timeBase:Double = 0
  var playedTime:Double = 0
  //
  var isEOF = false
  var isPaused = false
  
  var pSwrCtx: OpaquePointer? = nil
	
  var MAX_AUDIO_FRAME_SIZE:Int32 = 192000
	
	var out_buffer: UnsafeMutablePointer<UInt8>? = nil
  var out_buffer_size:Int32 = 0
	
	// out audio data
	var sampleSize: Int = 16
	var sampleRate: Int32 = 44100
	var channel: Int = 2
  
  func open(path: String) -> Bool {
    avformat_network_init()
    let videoSourceURI = path.cString(using: .utf8)
    
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
    
    
    ret = av_find_best_stream(formatContext, AVMEDIA_TYPE_AUDIO, -1, -1, &audioDecoder, 0)
    if ret < 0 {
      print("Cannot find a audio stream in the input file\n")
      return false
    }
    audioStreamIndex = ret
    
    audioCodecCtx = avcodec_alloc_context3(audioDecoder)
    if audioCodecCtx == nil {
      return false
    }
    
    audioStream = formatContext?.pointee.streams![Int(audioStreamIndex)]
    
    ret = avcodec_parameters_to_context(audioCodecCtx, audioStream?.pointee.codecpar)
    if ret < 0 {
      return false
    }
    
    // sws
    pSwrCtx = swr_alloc()
    
    if audioCodecCtx!.pointee.sample_rate != sampleRate {
      sampleRate = audioCodecCtx!.pointee.sample_rate
    }
    
    let out_sample_rate:Int32 = sampleRate
    let out_channel_layout:UInt64 = UInt64(AV_CH_LAYOUT_STEREO)
    let out_channels = av_get_channel_layout_nb_channels(out_channel_layout)
    var out_nb_samples = (audioCodecCtx?.pointee.frame_size)!;
    let out_sample_fmt:AVSampleFormat = AV_SAMPLE_FMT_S16
    if out_nb_samples == 0 {
      out_nb_samples = 1024
    }
    
    out_buffer_size = av_samples_get_buffer_size(nil, out_channels, out_nb_samples, out_sample_fmt, 1)
    let c = av_malloc(Int(MAX_AUDIO_FRAME_SIZE * 2))
    out_buffer = c?.assumingMemoryBound(to: UInt8.self)
    
    let in_channel_layout = av_get_default_channel_layout((audioCodecCtx?.pointee.channels)!);
    pSwrCtx = swr_alloc_set_opts(
      pSwrCtx,
      Int64(out_channel_layout),
      out_sample_fmt,
      out_sample_rate,
      in_channel_layout,
      (audioCodecCtx?.pointee.sample_fmt)!,
      (audioCodecCtx?.pointee.sample_rate)!,
      0,
      nil
    )
		
    swr_init(pSwrCtx);
    
    if (audioStream!.pointee.time_base.den >= 1) && (audioStream!.pointee.time_base.num >= 1) {
      timeBase = av_q2d(audioStream!.pointee.time_base)
    } else if (audioCodecCtx!.pointee.time_base.den >= 1) && (audioCodecCtx!.pointee.time_base.num >= 1) {
      timeBase = av_q2d(audioCodecCtx!.pointee.time_base)
    } else {
      timeBase = 0.04
    }
    duration = Double((audioStream?.pointee.duration)!) * timeBase
    
    ret = avcodec_open2(audioCodecCtx, audioDecoder, nil)
    if ret < 0 {
      print("Failed to open codec for stream \(String(audioStreamIndex))\n")
      return false
    }
    
    av_dump_format(formatContext, 0, videoSourceURI, 0)
    return true
  }
  
  func decode(_ size: UnsafeMutablePointer<UInt32>, _ buffer: UnsafeMutablePointer<UInt8>) {
    var frame:UnsafeMutablePointer<AVFrame>? = nil
    let packet = av_packet_alloc()
    
    if isPaused {
      return
    }
    ret = av_read_frame(formatContext, packet)
    if ret < 0 {
      isEOF = true
      return
    }
    
    if (packet?.pointee.stream_index)! == audioStreamIndex {
      
      var ret2:Int32 = avcodec_send_packet(audioCodecCtx, packet);
      if (ret2 < 0) {
        print("Error during decoding\n")
      }
      frame = av_frame_alloc()
      while ret2 >= 0 {
        ret2 = avcodec_receive_frame(audioCodecCtx, frame)
        if ret2 < 0 {
          return
        }
        playedTime = Double((frame?.pointee.pts)!) * timeBase
        
        var data = [UnsafePointer(frame?.pointee.data.0), UnsafePointer(frame?.pointee.data.1), UnsafePointer(frame?.pointee.data.2), UnsafePointer(frame?.pointee.data.3), UnsafePointer(frame?.pointee.data.4), UnsafePointer(frame?.pointee.data.5), UnsafePointer(frame?.pointee.data.6), UnsafePointer(frame?.pointee.data.7)]
        swr_convert(pSwrCtx, &out_buffer, MAX_AUDIO_FRAME_SIZE, &data, (frame?.pointee.nb_samples)!);
//				print("ret: \(ret)")
        size.pointee = UInt32(out_buffer_size)
        buffer.pointee = out_buffer!.pointee
      }
      
    }
    av_packet_unref(packet)
    
    av_frame_free(&frame);
  }
  
}

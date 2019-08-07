
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
	// out audio data
	var audioChannels:Int32 = 0
	var audioSampleRate:Int32 = 0
	
	
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
		let swsctx = swr_alloc_set_opts(nil, av_get_default_channel_layout(audioChannels), AV_SAMPLE_FMT_S16, audioSampleRate, av_get_default_channel_layout((audioCodecCtx?.pointee.channels)!), (audioCodecCtx?.pointee.sample_fmt)!, (audioCodecCtx?.pointee.sample_rate)!, 0, nil)
		if swsctx == nil {
			print("xxxxx")
		}
		ret = swr_init(swsctx)
		if ret < 0 {
			print("xxxxxyyyyy")
		}
		
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
	
	func decode()  {
		var frame:UnsafeMutablePointer<AVFrame>? = nil
		let packet = av_packet_alloc()
		
		while !isEOF {
			if isPaused {
				break
			}
			ret = av_read_frame(formatContext, packet)
			if ret < 0 {
				isEOF = true
				break
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
						break
					}
					playedTime = Double((frame?.pointee.pts)!) * timeBase
					
					// 2st
					var data = (frame?.pointee.data.0)!
					let cls = frame?.pointee.nb_samples
					
					let e = Int(cls! * audioChannels)
					let ssize = e * MemoryLayout<Float>.size
					var mdata = Data.init(count: ssize)
					let scalar = Float(1 / INT16_MAX)
					
//					vDSP_vflt16(data, 1, mdata.mutableBytes, 1, e);
//					vDSP_vsmul(mdata.w, 1, &scalar, mdata.mutableBytes, 1, e);
					
				
				}
				
			}
			av_packet_unref(packet)
		}
		av_frame_free(&frame);
		//		swr_free(&au_convert_ctx);
	}
	
}

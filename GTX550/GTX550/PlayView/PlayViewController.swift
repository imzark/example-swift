//
//  ViewController.swift
//  GTX550
//
//  Created by Harry Tang on 2019/6/10.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

import Cocoa
import Foundation
import AVFoundation
import VideoToolbox

var audio_len: UInt32 = 0
var audio_pos: UnsafePointer<UInt8>? = nil

class PlayViewController: NSViewController {
	
	var url:String = ""
	
	@IBOutlet weak var playButton: NSButton!
	@IBOutlet weak var progress: NSProgressIndicator!
	@IBOutlet weak var progress1: ProgressBarView!
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
	
//  var wanted_spec: SDL_AudioSpec? = nil
	var au_convert_ctx: OpaquePointer? = nil
	var out_buffer: UnsafeMutablePointer<UInt8>? = nil
	var out_buffer_size:Int32 = 0
	// 处理放回结果
	var ret:Int32 = 0
	// 时间
	var duration:Double = 0
	var timeBase:Double = 0
	var playedTime:Double = 0
	//
	var isEOF = false
	var isPaused = false
	
	var MAX_AUDIO_FRAME_SIZE:Int32 = 192000
	
	override func viewDidLoad() {
		super.viewDidLoad()
		var success = open(path: url)
		if success {
			success = setupAudio()
			progress.startAnimation(nil)
			progress1.value = 0.0
			progress1.handleSeek = { (seek: Double) -> Bool in
				print(seek, AV_TIME_BASE, self.timeBase)
				let ss = Int64(seek / 100 * self.duration / self.timeBase)
				print(ss)
				av_seek_frame(self.formatContext, self.audioStreamIndex, ss, 0)
				return true
			}
			DispatchQueue.global().async {
				self.decode()
			}
			// seek
//			progress.mou
		}
	}
	
	@IBAction func clickPlayButton(_ sender: Any) {
		self.isPaused = !self.isPaused
		playButton.image = NSImage.init(named: self.isPaused ? .play : .pause)
		if !self.isPaused {
			DispatchQueue.global().async {
				self.decode()
			}
		}
	}
	
	
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
	
	func setupAudio() -> Bool {
		// SDL hanlder
//    if SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER) != 0 {
//      print("Could not initialize SDL - \(String(describing: SDL_GetError()))\n")
//      return false
//    }
//
//    let out_sample_rate:Int32 = (audioCodecCtx?.pointee.sample_rate)!
//    let out_channel_layout:UInt64 = UInt64(AV_CH_LAYOUT_STEREO)
//    let out_channels = av_get_channel_layout_nb_channels(out_channel_layout)
//    var out_nb_samples = (audioCodecCtx?.pointee.frame_size)!;
//    let out_sample_fmt:AVSampleFormat = AV_SAMPLE_FMT_S16
//    if out_nb_samples == 0 {
//      out_nb_samples = 1024
//    }
//
//    out_buffer_size = av_samples_get_buffer_size(nil, out_channels, out_nb_samples, out_sample_fmt, 1)
//    let c = av_malloc(Int(MAX_AUDIO_FRAME_SIZE * 2))
//    out_buffer = c?.assumingMemoryBound(to: UInt8.self)
//
//    wanted_spec = SDL_AudioSpec.init()
//    wanted_spec!.freq = out_sample_rate;
//    wanted_spec!.format = SDL_AudioFormat(AUDIO_S16SYS);
//    wanted_spec!.channels = Uint8(out_channels);
//    wanted_spec!.silence = 0;
//    wanted_spec!.samples =  Uint16(out_nb_samples);
//    wanted_spec!.callback = { (udata: UnsafeMutableRawPointer?, stream: UnsafeMutablePointer<UInt8>?, len:Int32) in
//      // 静音
//      SDL_memset(stream, 0, Int(len))
//      if audio_len == 0 {
//        return
//      }
//      var l = UInt32(len)
//      if len > Int32(audio_len) {
//        l = UInt32(audio_len)
//      }
//      SDL_MixAudio(stream, audio_pos, l, SDL_MIX_MAXVOLUME)
//      audio_pos = audio_pos! + Int(l)
//      audio_len -= l
//    }
//    wanted_spec!.userdata = UnsafeMutableRawPointer(audioCodecCtx);
//
//    if SDL_OpenAudio(&wanted_spec!, nil) < 0{
//      print("can't open audio.\n");
//      return false
//    }
//
//    let in_channel_layout = av_get_default_channel_layout((audioCodecCtx?.pointee.channels)!);
//    //Swr
//    au_convert_ctx = swr_alloc()
//    au_convert_ctx = swr_alloc_set_opts(au_convert_ctx, Int64(out_channel_layout), out_sample_fmt, out_sample_rate, in_channel_layout, (audioCodecCtx?.pointee.sample_fmt)!, (audioCodecCtx?.pointee.sample_rate)!, 0, nil)
//    swr_init(au_convert_ctx);
//
//    //Play
//    SDL_PauseAudio(1)
		return true
	}
	
	func decode()  {
//    SDL_PauseAudio(0)
		var frame:UnsafeMutablePointer<AVFrame>? = nil
		let packet = av_packet_alloc()
	
		while !isEOF {
			if isPaused {
				break
			}
			ret = av_read_frame(formatContext, packet)
			if ret < 0 {
				isEOF = true
//        SDL_PauseAudio(1)
				DispatchQueue.main.async {
					self.progress1.value = 100.0
					self.progress.doubleValue = 100
					self.repeatPlay()
				}
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
					var data = [UnsafePointer(frame?.pointee.data.0), UnsafePointer(frame?.pointee.data.1), UnsafePointer(frame?.pointee.data.2), UnsafePointer(frame?.pointee.data.3), UnsafePointer(frame?.pointee.data.4), UnsafePointer(frame?.pointee.data.5), UnsafePointer(frame?.pointee.data.6), UnsafePointer(frame?.pointee.data.7)]
					swr_convert(au_convert_ctx, &out_buffer, MAX_AUDIO_FRAME_SIZE, &data, (frame?.pointee.nb_samples)!);
					
					while audio_len > 0 {
//            SDL_Delay(1);
					}
					//Audio buffer length
					audio_len = UInt32(out_buffer_size)
					//Set audio buffer (PCM data)
					audio_pos = UnsafePointer(out_buffer)
					// 显示进度
					DispatchQueue.main.async {
						self.progress1.value = (self.playedTime / self.duration) * 100
						self.progress.doubleValue = (self.playedTime / self.duration) * 100
					}
				}
				
			}
			av_packet_unref(packet)
		}
		av_frame_free(&frame);
//		swr_free(&au_convert_ctx);
	}
	
	func repeatPlay() {
		self.progress1.value = 0.0
		self.progress.doubleValue = 0
		DispatchQueue.global().async {
			self.isEOF = false
			self.isPaused = false
			av_seek_frame(self.formatContext, self.audioStreamIndex, 0, 0)
			self.decode()
		}
	}
}

extension NSImage.Name {
	static let play = NSImage.Name("Play")
	static let pause = NSImage.Name("Pause")
}

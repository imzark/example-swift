//
//  AudioPlayer.swift
//  GTX550
//
//  Created by harry on 2019/8/9.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

import OpenAL
import AudioToolbox
import Foundation


class AudioPlayer {
  var device: OpaquePointer? = nil
  var context: OpaquePointer? = nil
  var source: ALuint = ALuint.init()
  
  var decoder: AudioDecoder = AudioDecoder()
  public func start (_ path: String) {
    
    device = alcOpenDevice(nil)
		checkALError("alcOpenDevice")
    
    context = alcCreateContext(device, nil)
		checkALError("alcCreateContext")
    
    alcMakeContextCurrent(context)
		checkALError("alcMakeContextCurrent")
    
    alGenSources(1, &source)
		checkALError("alGenSources")
    
    alSpeedOfSound(1.0);
		checkALError("alSpeedOfSound")
    alDopplerVelocity(1.0);
		checkALError("alDopplerVelocity")
    alDopplerFactor(1.0);
		checkALError("alDopplerFactor")
    alSourcef(source, AL_PITCH, 1.0);
		checkALError("alSourcef")
    alSourcef(source, AL_GAIN, 1.0);
		checkALError("alSourcef")
    alSourcei(source, AL_LOOPING, AL_FALSE);
		checkALError("alSourcei")
//    alSourcef(source, AL_SOURCE_TYPE, ALfloat(AL_STREAMING));
//		checkALError("alSourcef")
    
    if decoder.open(path: path) {
      print("success \n")
    }
    
  }
  
  public func play() {
//    while !decoder.isEOF {
			var len: UInt32 = 0
			var buffer: UInt8 = UInt8.init()
			decoder.decode(&len, &buffer)
			print("len: \(len) buffer: \(buffer)")
//			print("size: \(decoder.sampleSize), rate: \(decoder.sampleRate), channel: \(decoder.channel)")
			//创建一个buffer
			if len > 0 {
				var format = ALenum.init()
				var bufferID: ALuint = 0
				alGenBuffers(1, &bufferID);
				// error check
				checkALError("alGenBuffers")
				
				if decoder.sampleSize == 16 && decoder.channel == 2 {
					format = AL_FORMAT_STEREO16
				}
				print("rate: \(decoder.sampleRate)")
				alBufferData(bufferID, format, &buffer, ALsizei(len), decoder.sampleRate)
				// error check
				checkALError("alBufferData")
				
				
//				alSourcei(source, AL_BUFFER, ALint(bufferID))
				alSourceQueueBuffers(source, 1, &bufferID);
				checkALError("alSourceQueueBuffers")
				
				var state = ALint.init()
				alGetSourcei(source, AL_SOURCE_STATE, &state);
				checkALError("alGetSourcei")
				print("state: \(state)")

//				if state == AL_STOPPED || state == AL_PAUSED || state == AL_INITIAL {
//					print("state: \(state)")
//					if state != AL_PLAYING {
//						alSourcePlay(source)
//						checkALError("play fail")
//					}
//				}
				
			}
			
//    }
  }
	
	private func checkALError(_ message: String) {
		let alError = alGetError()
		if alError != AL_NO_ERROR {
			switch (alError) {
			case AL_INVALID_NAME:
				print("OpenAL Error: \(AL_INVALID_NAME); \(message)")
				break
			case AL_INVALID_VALUE:
				print("OpenAL Error: \(AL_INVALID_VALUE); \(message)")
				break
			case AL_INVALID_ENUM:
				print("OpenAL Error: \(AL_INVALID_ENUM); \(message)")
				break
			case AL_INVALID_OPERATION:
				print("OpenAL Error: \(AL_INVALID_OPERATION); \(message)")
				break
			case AL_OUT_OF_MEMORY:
				print("OpenAL Error: \(AL_OUT_OF_MEMORY); \(message)")
				break
			default:
				print("OpenAL Error: \(message)")
			}
		}
	}
}
//let data = [UInt8](repeating: 0, count: 1)
//lock.lock()
//data[0] = UInt8(dataBuf)
//let len = swr_convert(pSwrCtx, data, 10000, UInt8(pPcm.data), pPcm.nb_samples)
//if len < 0 {
//    lock.unlock()
//    return 0
//}
//
//let tempData = Int8(malloc(10000))


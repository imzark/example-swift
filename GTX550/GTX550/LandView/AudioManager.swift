//
//  AudioDecoder.swift
//  GTX550
//
//  Created by Harry Tang on 2019/6/15.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

import Foundation
import AudioToolbox
import AudioUnit
import CoreAudio

func abridge<T : AnyObject>(obj : T) -> UnsafeRawPointer {
	return UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque())
}

func abridge<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
	return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
}

func abridgeRetained<T : AnyObject>(obj : T) -> UnsafeRawPointer {
	return UnsafeRawPointer(Unmanaged.passRetained(obj).toOpaque())
}

func abridgeTransfer<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
	return Unmanaged<T>.fromOpaque(ptr).takeRetainedValue()
}

private let sampleRate = 44100
private let amplitude: Float = 1.0
private let frequency: Float = 440

// theta is changed over time as each sample is provided
private var theta: Float = 0.0

private func renderCallBack(inRefCon: UnsafeMutableRawPointer, ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, inTimeStamp: UnsafePointer<AudioTimeStamp>, inBusNumber: UInt32, inNumberFrames: UInt32, ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
	let r = UnsafeRawPointer(inRefCon)
	let instance: AudioManager = abridge(ptr: r)
	return instance.render(ioData: ioData!, count: inNumberFrames)
}

class AudioManager {
	
	var bitsPerChannel: UInt32 = 0
	var channelsPerFrame: UInt32 = 0
	private var audioUnit: AudioUnit? = nil
	
	var audioIndex = Float64(0)
	
	init() {
		setupAudioUnit()
	}
	
	func setupAudioUnit() {
		// configure the description os the output audio component we want to find:
		var defaultOutputDescription = AudioComponentDescription(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_DefaultOutput, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
		let defaultOutput = AudioComponentFindNext(nil, &defaultOutputDescription)
		var err: OSStatus
		err = AudioComponentInstanceNew(defaultOutput!, &audioUnit)
		if err != noErr {
			print("AudioComponentInstanceNew Failed")
		}
		
		// set the stream format fot the audio unit, that is then format if the data that our render callback will provide
		var streamFormat = AudioStreamBasicDescription(mSampleRate: Float64(sampleRate), mFormatID: kAudioFormatLinearPCM, mFormatFlags: kAudioFormatFlagsNativeFloatPacked|kAudioFormatFlagIsNonInterleaved, mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: 1, mBitsPerChannel: 4 * 8, mReserved: 0)
		streamFormat.mSampleRate = Float64(sampleRate)
		err = AudioUnitSetProperty(audioUnit!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
		if err != noErr {
			print("AudioUnitProperty StreamFormat Failed")
		}
		
		bitsPerChannel = streamFormat.mBitsPerChannel
		channelsPerFrame = streamFormat.mChannelsPerFrame
		
		// create a new instance of it in the form of our audio unit
		let r = UnsafeMutableRawPointer(mutating: abridge(obj: self))
		var renderCallBackStruct = AURenderCallbackStruct(inputProc: renderCallBack, inputProcRefCon: r)
		err = AudioUnitSetProperty(audioUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallBackStruct, UInt32(MemoryLayout<AURenderCallbackStruct>.size))
		if err != noErr {
			print("AudioUnitSetProperty SetRenderCallBack Failed")
		}
		
		AudioUnitInitialize(audioUnit!)
	}
	
	func play() {
		let status = AudioOutputUnitStart(audioUnit!)
		if status != noErr {
			print("error")
		}
	}
	
	func render(ioData: UnsafeMutablePointer<AudioBufferList>, count: UInt32) -> OSStatus {
		// first 静音
		print(ioData.pointee)
		let buf = ioData.pointee.mBuffers
		print(buf.mNumberChannels)
		memset(buf.mData, 0, Int(buf.mDataByteSize))
		
		if bitsPerChannel == 32 {
			var scalar: Float = 0
			let buf = ioData.pointee.mBuffers
			let channels = buf.mNumberChannels
			
			for i in 0..<channels {
				//				vDSP_vsadd()
			}
		}
		
		//		let abl = UnsafeMutableAudioBufferListPointer(ioData)
		//		let buffer = abl[0]
		//		let pointer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(buffer)
		//		for frame in 0..<count {
		//			let pointerIndex = pointer.startIndex.advanced(by: Int(frame))
		//			pointer[pointerIndex] = sin(theta) * amplitude
		//			theta += 2.0 * Float(M_PI) * frequency / Float(sampleRate)
		//		}
		
		return noErr
	}
}


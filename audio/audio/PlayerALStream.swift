//
//  PlayerALStream.swift
//  audio
//
//  Created by harry on 2019/8/12.
//  Copyright © 2019 harry. All rights reserved.
//

import Foundation
import OpenAL
import AudioToolbox

// MARK: user data struct

struct MyStreamPlayer {
  var dataFormat: AudioStreamBasicDescription
  var bufferSizeBytes: UInt32
  var fileLengthFrames: sint64
  var totalFramesRead: sint64
  var source: [ALuint]
  var extAudioFile: ExtAudioFileRef?
  init() {
    dataFormat = AudioStreamBasicDescription.init()
    bufferSizeBytes = UInt32.init()
    fileLengthFrames = sint64.init()
    totalFramesRead = sint64.init()
    source = [ALuint].init(repeating: ALuint.init(), count: 1)
    extAudioFile = nil
  }
}


// MARK: utility functions


class PlayerALStream {
  public func start() {
    var player = MyStreamPlayer.init()
    // MARK: prepare the extaudiofile
    setUpExtAudioFile(&player, "/Users/harry/Music/test.mp3")
    
    // MARK: set up openal buffers
    let device = alcOpenDevice(nil)
    checkALError ("Couldn't open AL device")
    
    let context = alcCreateContext(device, nil)
    checkALError ("Couldn't open AL context")
    
    alcMakeContextCurrent(context)
    checkALError ("Couldn't make AL context current")
    
    var buffers = [ALuint].init(repeating: ALuint.init(), count: 3)
    alGenBuffers(3, &buffers)
    checkALError("generate buffers fail")
    
    for i in 0..<3 {
      fillALBuffer(&player, buffers[i]);
    }
    
    // MARK: set up streaming  source
    alGenSources(1, &player.source)
    checkALError("Couldn't generate sources")
    
    alSourcef(player.source[0], AL_GAIN, ALfloat(AL_MAX_GAIN))
    checkALError("Couldn't set source gain")
    
    // MARK: queue up the buffers on the source
    alSourceQueueBuffers(player.source[0], 3, buffers)
    checkALError("Couldn't queue buffers on source")
    
    // MARK: set up listener
    alListener3f(AL_POSITION, 0.0, 0.0, 0.0)
    checkALError("Couldn't set listner position")
    
    // MARK: start playing
    alSourcePlayv(1, &player.source)
    checkALError("Couldn't play")
    
    let startTime = time(nil)
    repeat {
      refillALBuffers(&player)
    } while (difftime(time(nil), startTime) < 100)
  }
  
  private func fillALBuffer(_ player: UnsafeMutablePointer<MyStreamPlayer>, _ buffer: ALuint) {
    var bufferList = AudioBufferList.allocate(maximumBuffers: 1)
    defer {
      free(bufferList.unsafeMutablePointer)
    }
    var sampleBuffer = UnsafeMutablePointer<UInt16>.allocate(capacity: Int(player.pointee.bufferSizeBytes))
    defer {
      free(sampleBuffer)
    }
    bufferList[0].mNumberChannels = 1
    bufferList[0].mDataByteSize = player.pointee.bufferSizeBytes
    bufferList[0].mData = UnsafeMutableRawPointer(sampleBuffer)
    
    var framesReadIntoBuffer: UInt32 = 0
    repeat {
      var framesRead = UInt32(player.pointee.fileLengthFrames) - framesReadIntoBuffer
      bufferList[0].mData = UnsafeMutableRawPointer(sampleBuffer + Int(framesReadIntoBuffer) * MemoryLayout<UInt16>.size)
      ExtAudioFileRead(player.pointee.extAudioFile!, &framesRead, bufferList.unsafeMutablePointer)
      framesReadIntoBuffer += framesRead
      player.pointee.totalFramesRead += sint64(framesRead)
      
    } while (framesReadIntoBuffer < player.pointee.bufferSizeBytes / UInt32(MemoryLayout<UInt16>.size))
    print("buffer: \(sampleBuffer.pointee)")
    alBufferData(buffer, AL_FORMAT_MONO16, sampleBuffer, ALsizei(player.pointee.bufferSizeBytes), ALsizei(player.pointee.dataFormat.mSampleRate))
  }
  
  private func refillALBuffers(_ player: UnsafeMutablePointer<MyStreamPlayer>) {
    var processed = ALint.init()
    alGetSourcei(player.pointee.source[0], AL_BUFFERS_PROCESSED, &processed)
    checkALError("couldn't get al_buffers_processed")
    
    while (processed > 0) {
      var freeBuffer = ALuint.init()
      alSourceUnqueueBuffers(player.pointee.source[0], 1, &freeBuffer)
      checkALError("couldn't unqueue buffer")
      
      fillALBuffer(player, freeBuffer)
      
      alSourceQueueBuffers(player.pointee.source[0], 1, &freeBuffer)
      checkALError("couldn't queue refilled buffer")
      
      processed -= 1
    }
  }
  
  private func setUpExtAudioFile(_ player: UnsafeMutablePointer<MyStreamPlayer>, _ path: String) {
    // MARK: describe client format
    player.pointee.dataFormat.mFormatID = kAudioFormatLinearPCM
    player.pointee.dataFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
    player.pointee.dataFormat.mSampleRate = 44100.0
    player.pointee.dataFormat.mChannelsPerFrame = 1
    player.pointee.dataFormat.mFramesPerPacket = 1
    player.pointee.dataFormat.mBitsPerChannel = 16
    player.pointee.dataFormat.mBytesPerFrame = 2
    player.pointee.dataFormat.mBytesPerPacket = 2
    
    // open audio file
    let loopFleURL = URL(fileURLWithPath: path)
    ExtAudioFileOpenURL((loopFleURL as CFURL), &player.pointee.extAudioFile)
    
    ExtAudioFileSetProperty(player.pointee.extAudioFile!, kExtAudioFileProperty_ClientDataFormat, UInt32(MemoryLayout<AudioStreamBasicDescription>.size), &player.pointee.dataFormat)
    
    var propSize = UInt32(MemoryLayout<sint64>.size)
    ExtAudioFileGetProperty(player.pointee.extAudioFile!, kExtAudioFileProperty_FileLengthFrames, &propSize, &player.pointee.fileLengthFrames)
    
    player.pointee.bufferSizeBytes = 1 *
    UInt32(player.pointee.dataFormat.mSampleRate) *
    player.pointee.dataFormat.mBytesPerFrame
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

//
//  PlayAL.swift
//  audio
//
//  Created by harry on 2019/8/7.
//  Copyright © 2019 harry. All rights reserved.
//

import Foundation
import OpenAL
import AudioToolbox

// MARK: user data

struct OpenALPlayer {
  var dataFormat: AudioStreamBasicDescription
  var sampleBuffer: UnsafeMutablePointer<UInt16>?
  var bufferSizeBytes: UInt32
  var source: [ALuint]
  init() {
    dataFormat = AudioStreamBasicDescription.init()
    sampleBuffer = nil
    bufferSizeBytes = UInt32.init()
    source = [ALuint].init(repeating: ALuint.init(), count: 1)
  }
}

// MARK: utility functions


class PlayAL {
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
  public func start () {
    var player = OpenALPlayer.init()
    // MARK: convert to a open-al format
    loadLoopIntoBuffer(&player, "/Users/harry/Music/1.mp3" as CFString)
    
    // MARK: set up openal buffer
    let alDevice = alcOpenDevice(nil)
    checkALError("open al device fail")
    
    let alContext = alcCreateContext(alDevice, nil)
    checkALError("open al context fail")
    
    alcMakeContextCurrent(alContext)
    checkALError("make al context fail")
    
    var buffers = [ALuint].init(repeating: ALuint.init(), count: 1)
    alGenBuffers(1, &buffers)
    checkALError("generate buffers fail")
    
    alBufferData(buffers[0], AL_FORMAT_MONO16, player.sampleBuffer, ALsizei(player.bufferSizeBytes), ALsizei(player.dataFormat.mSampleRate))
    checkALError("copy fail")
    
    free(player.sampleBuffer)
    
    // MARK: set up openal source
    alGenSources(1, &player.source)
    checkALError("generate source fail")
    
    alSourcei(player.source[0], AL_LOOPING, AL_TRUE)
    checkALError("set source looping fail")
    
    alSourcef(player.source[0], AL_GAIN, ALfloat(AL_MAX_GAIN))
    checkALError("set source gain fail")
    
    // MARK: connect buffer to source
    alSourcei(player.source[0], AL_BUFFER, ALint(buffers[0]))
    checkALError("connect buffer to source fail")
    
    // MARK: set up openal listener
    alListener3f(AL_POSITION, 0.0, 0.0, 0.0)
    checkALError("set listener position fail")
    
    // MARK: start playing
    alSourcePlay(player.source[0])
    checkALError("playing fail")
  }
  
  private func loadLoopIntoBuffer(_ player: UnsafeMutablePointer<OpenALPlayer>, _ path: CFString) -> OSStatus {
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
    let loopFleURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path, CFURLPathStyle.cfurlposixPathStyle, false)
    var extAudioFile: ExtAudioFileRef? = nil
    ExtAudioFileOpenURL(loopFleURL!, &extAudioFile)
    
    ExtAudioFileSetProperty(extAudioFile!, kExtAudioFileProperty_ClientDataFormat, UInt32(MemoryLayout<AudioStreamBasicDescription>.size), &player.pointee.dataFormat)
    
    
    var fileLengthFrames = sint64.init()
    var propSize = UInt32(MemoryLayout<sint64>.size)
    ExtAudioFileGetProperty(extAudioFile!, kExtAudioFileProperty_FileLengthFrames, &propSize, &fileLengthFrames)
    
    player.pointee.bufferSizeBytes = UInt32(fileLengthFrames) * player.pointee.dataFormat.mBytesPerFrame
    
    let buffers: UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: 1)
    
    player.pointee.sampleBuffer = UnsafeMutablePointer<UInt16>.allocate(capacity: Int(player.pointee.bufferSizeBytes))
    
    buffers[0].mNumberChannels = 1
    buffers[0].mDataByteSize = player.pointee.bufferSizeBytes
    buffers[0].mData = UnsafeMutableRawPointer(player.pointee.sampleBuffer)
    
    var totalFramesRead: UInt32 = 0
    
    repeat {
      var framesRead = UInt32(fileLengthFrames) - totalFramesRead
      guard let sampleBuffer = player.pointee.sampleBuffer else {
        break
      }
      buffers[0].mData = UnsafeMutableRawPointer(sampleBuffer + Int(totalFramesRead + UInt32(MemoryLayout<UInt16>.size)))
      ExtAudioFileRead(extAudioFile!, &framesRead, buffers.unsafeMutablePointer)
//			print(buffers[0].mData)
//			print(player.pointee.sampleBuffer?.pointee)
      totalFramesRead += framesRead
    } while (totalFramesRead < UInt32(fileLengthFrames))
    
    
    free(buffers.unsafeMutablePointer)
    
    return noErr
  }
}


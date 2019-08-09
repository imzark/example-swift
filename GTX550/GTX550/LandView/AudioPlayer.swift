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
    
    context = alcCreateContext(device, nil)
    
    alcMakeContextCurrent(context)
    
    alGenSources(1, &source)
    
    alSpeedOfSound(1.0);
    alDopplerVelocity(1.0);
    alDopplerFactor(1.0);
    alSourcef(source, AL_PITCH, 1.0);
    alSourcef(source, AL_GAIN, 1.0);
    alSourcei(source, AL_LOOPING, AL_FALSE);
    alSourcef(source, AL_SOURCE_TYPE, ALfloat(AL_STREAMING));
    
    if decoder.open(path: path) {
      print("success \n")
    }
    
  }
  
  public func play() {
    alSourcePlay(source);
    var len: UInt32 = 0
    var buffer: UInt8 = 1
    while !decoder.isEOF {
      decoder.decode(&len, &buffer)
      print("len: \(len) buffer: \(buffer)")
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


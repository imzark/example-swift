//
//  PlayAudioBuffer.swift
//  audio
//
//  Created by harry on 2019/8/2.
//  Copyright © 2019 harry. All rights reserved.
//
import AudioToolbox
import Foundation

struct MyBufferPlayer {
  var outputUnit:AudioUnit?
  var startingFrameCount:Double
  init() {
    outputUnit = nil
    startingFrameCount = 0.0
  }
}
private let sineFrequency:Double = 880.0
// UnsafeMutableRawPointer, UnsafeMutablePointer<AudioUnitRenderActionFlags>, UnsafePointer<AudioTimeStamp>, UInt32, UInt32, Optional<UnsafeMutablePointer<AudioBufferList>>
private let Call: AURenderCallback = {
  (ref: UnsafeMutableRawPointer,
  flags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
  stamp: UnsafePointer<AudioTimeStamp>,
  inBusNumber: UInt32,
  inNumberFrames: UInt32,
  ioData: UnsafeMutablePointer<AudioBufferList>?) in
  
  var player = ref.assumingMemoryBound(to: MyBufferPlayer.self)
  
  var j = player.pointee.startingFrameCount
  var cycleLength = 44100.0 / sineFrequency
  
  let abl = UnsafeMutableAudioBufferListPointer(ioData)!
  let buffer = abl[0]
  let pointer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(buffer)
  let buffer1 = abl[1]
  let pointer1: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(buffer1)
  for i in 0..<Int(inNumberFrames) {
    let frameData: Float32 = Float32(sin(2 * Double.pi * (j / cycleLength)))
    let pointerIndex = pointer.startIndex.advanced(by: i)
    pointer[pointerIndex] = frameData
    let pointerIndex1 = pointer1.startIndex.advanced(by: i)
    pointer1[pointerIndex1] = frameData
    j += 1.0
    if j > cycleLength {
        j -= cycleLength
    }
  }
  
  //    for (frame = 0; frame < inNumberFrames; ++frame)
  //    {
  //        Float32 *data = (Float32*)ioData->mBuffers[0].mData;
  //        (data)[frame] = (Float32)sin (2 * M_PI * (j / cycleLength));
  //
  //        // copy to right channel too
  //        data = (Float32*)ioData->mBuffers[1].mData;
  //        (data)[frame] = (Float32)sin (2 * M_PI * (j / cycleLength));
  //
  //        j += 1.0;
  //        if (j > cycleLength)
  //        j -= cycleLength;
  //    }
  
  //    for i in 0..<Int(inNumberFrames) {
  //        let buffer1 = abl[0]
  //        let buffer2 = abl[1]
  //
  //        let capacity: Int = Int(buffer1.mDataByteSize / UInt32(MemoryLayout<Float32>.size))
  //        let frameData: Float32 = Float32(sin(2 * Double.pi * (j / cycleLength)))
  //
  //        if let data = abl[0].mData {
  ////            let x = data.assumingMemoryBound(to: Float32.self)
  ////            x.pointee = frameData
  //            var float32Data = data.bindMemory(to: Float32.self, capacity: capacity)
  //            float32Data[i] = frameData
  //        }
  //
  //        if let data = abl[1].mData {
  ////            let x = data.assumingMemoryBound(to: Float32.self)
  ////            x.pointee = frameData
  //            var float32Data = data.bindMemory(to: Float32.self, capacity: capacity)
  //            float32Data[i] = frameData
  //        }
  //
  //        j += 1.0
  //        if j > cycleLength {
  //            j -= cycleLength
  //        }
  //    }
  
  player.pointee.startingFrameCount = j
  
  return noErr
  
}

class PlayAudioBuffer {
  
  public func start() {
    var player = MyBufferPlayer.init()
    
    // MARK: set up unit and callback
    createAndConnectOutputUnit(&player)
    
    // MARK: start playing
    AudioOutputUnitStart(player.outputUnit!)
    
  }
  
  private func createAndConnectOutputUnit(_ player: UnsafeMutablePointer<MyBufferPlayer>) {
    var outputcd = AudioComponentDescription.init()
    outputcd.componentType = kAudioUnitType_Output
    outputcd.componentSubType = kAudioUnitSubType_DefaultOutput
    outputcd.componentManufacturer = kAudioUnitManufacturer_Apple
    
    let comp = AudioComponentFindNext(nil, &outputcd)
    if comp != nil {
      AudioComponentInstanceNew(comp!, &player.pointee.outputUnit)
      var input = AURenderCallbackStruct.init()
      input.inputProc = Call
      input.inputProcRefCon = UnsafeMutableRawPointer.init(player)
      
      AudioUnitSetProperty(player.pointee.outputUnit!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &input, UInt32(MemoryLayout<AURenderCallbackStruct>.size))
      
      AudioUnitInitialize(player.pointee.outputUnit!)
    }
  }
  
}

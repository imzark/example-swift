//
//  PlayAudioSpeech.swift
//  audio
//
//  Created by harry on 2019/8/5.
//  Copyright © 2019 harry. All rights reserved.
//

import Foundation
import AudioToolbox

// MARK: user data

struct SpeechPlayer {
  var graph: AUGraph?
  var speechAU: AudioUnit?
  init() {
    graph = nil
    speechAU = nil
  }
}

// MARK: utility functions

class PlayAudioSpeech {
  public func start() {
    var player = SpeechPlayer.init()
    // MARK: build a basic speech speakers graph
    createMyAUGraph(&player)
    
    // MARK: configura then speech synthesizer
    prepareSpeechAU(&player)
    
    // MARK: start playing
    AUGraphStart(player.graph!)
  }
  private func createMyAUGraph(_ player: UnsafeMutablePointer<SpeechPlayer>) {
    NewAUGraph(&player.pointee.graph)
    
    var outputcd = AudioComponentDescription.init()
    outputcd.componentType = kAudioUnitType_Output
    outputcd.componentSubType = kAudioUnitSubType_DefaultOutput
    outputcd.componentManufacturer = kAudioUnitManufacturer_Apple
    
    var outputNode = AUNode.init()
    AUGraphAddNode(player.pointee.graph!, &outputcd, &outputNode)
    
    var speechcd = AudioComponentDescription.init()
    speechcd.componentType = kAudioUnitType_Generator
    speechcd.componentSubType = kAudioUnitSubType_SpeechSynthesis
    speechcd.componentManufacturer = kAudioUnitManufacturer_Apple
    
    var speechNode = AUNode.init()
    AUGraphAddNode(player.pointee.graph!, &speechcd, &speechNode)
    
    AUGraphOpen(player.pointee.graph!)
    
    AUGraphNodeInfo(player.pointee.graph!, speechNode, nil, &player.pointee.speechAU)
    
    // MARK: add effect
    var reverbcd = AudioComponentDescription.init()
    reverbcd.componentType = kAudioUnitType_Effect
    reverbcd.componentSubType = kAudioUnitSubType_MatrixReverb
    reverbcd.componentManufacturer = kAudioUnitManufacturer_Apple
    
    var reverbNode = AUNode.init()
    AUGraphAddNode(player.pointee.graph!, &reverbcd, &reverbNode)
    
    AUGraphConnectNodeInput(player.pointee.graph!, speechNode, 0, reverbNode, 0)
    
    AUGraphConnectNodeInput(player.pointee.graph!, reverbNode, 0, outputNode, 0)
    
    var reverbUnit:AudioUnit? = nil
    let s = AUGraphNodeInfo(player.pointee.graph!, reverbNode, nil, &reverbUnit)
    print("d: \(PlayAudio.checkStatus(s))")
    
    AUGraphInitialize(player.pointee.graph!)
    var roomType = 8
    AudioUnitSetProperty(reverbUnit!, kAudioUnitProperty_ReverbRoomType, kAudioUnitScope_Global, 0, &roomType, UInt32(MemoryLayout<UInt32>.size))
  }
  
  private func prepareSpeechAU(_ player: UnsafeMutablePointer<SpeechPlayer>) {
    var chan: SpeechChannel? = nil
    var propSize = UInt32(MemoryLayout<SpeechChannel>.size)
    AudioUnitGetProperty(player.pointee.speechAU!, kAudioUnitProperty_SpeechChannel, kAudioUnitScope_Global, 0, &chan, &propSize)
    
    SpeakCFString(chan!, "with you, some suger, do not go that way" as CFString, nil)
  }
}

//
//  PlayAudioUnit.swift
//  audio
//
//  Created by harry on 2019/8/2.
//  Copyright © 2019 harry. All rights reserved.
//
import AudioToolbox
import Foundation

// MARK: user data
struct MyUnitPlayer {
    var inputFormat: AudioStreamBasicDescription
    var inputFile: AudioFileID?
    var graph: AUGraph?
    var fileAU: AudioUnit?
    init() {
        inputFormat = AudioStreamBasicDescription.init()
        inputFile = nil
        graph = nil
        fileAU = nil
    }
}

// MARK: utility functions

class PlayAudioUnit {
    public func start() {
        // MARK: open the audio file
        var player = MyUnitPlayer.init()
        let kPlaybackFileLocation = "/Users/harry/Music/test.mp3" as CFString
        let myFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, kPlaybackFileLocation, CFURLPathStyle.cfurlposixPathStyle, false)!
        AudioFileOpenURL(myFileURL, AudioFilePermissions.readWritePermission, 0,  &player.inputFile)
        
        // MARK: get the audio format from the file
        var propSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        AudioFileGetProperty(player.inputFile!, kAudioFilePropertyDataFormat, &propSize, &player.inputFormat)
        
        // MARK: build a basic fileplayer.speakers graph
        createMyAUGraph(&player)
        
        // MARK: configure the file player
        let duration = prepareFileA(&player)
        
        // MARK: start playing
        let status = AUGraphStart(player.graph!)
        print("start: \(PlayAudio.checkStatus(status))")
        
        // MARK: sleep until the fuile is finished
        
        
        // MARK: clean up
        
        
    }
    
    private func createMyAUGraph(_ player: UnsafeMutablePointer<MyUnitPlayer>) {
        // create a new AUGraph
        NewAUGraph(&player.pointee.graph)
        
        // generate output device description
        var outputcd = AudioComponentDescription.init()
        outputcd.componentType = kAudioUnitType_Output
        outputcd.componentSubType = kAudioUnitSubType_DefaultOutput
        outputcd.componentManufacturer = kAudioUnitManufacturer_Apple
        
        // add output node to AUGraph
        var outputNode = AUNode.init()
        AUGraphAddNode(player.pointee.graph!, &outputcd, &outputNode)
        
        // generate input file description
        var fileplayercd = AudioComponentDescription.init()
        fileplayercd.componentType = kAudioUnitType_Generator
        fileplayercd.componentSubType = kAudioUnitSubType_AudioFilePlayer
        fileplayercd.componentManufacturer = kAudioUnitManufacturer_Apple
        
        // add input file node to AUGraph
        var fileNode = AUNode.init()
        AUGraphAddNode(player.pointee.graph!, &fileplayercd, &fileNode)
        
        // open graph
        AUGraphOpen(player.pointee.graph!)
        
        // get AudioUnit
        AUGraphNodeInfo(player.pointee.graph!, fileNode, nil, &player.pointee.fileAU)
        
        // connect output with input file
        AUGraphConnectNodeInput(player.pointee.graph!, fileNode, 0, outputNode, 0)
        
        // initialize AUGraph
        AUGraphInitialize(player.pointee.graph!)
    }
    
    private func prepareFileA(_ player: UnsafeMutablePointer<MyUnitPlayer>) -> Float64 {
        // first tell file player to load music file
        AudioUnitSetProperty(player.pointee.fileAU!, kAudioUnitProperty_ScheduledFileIDs, kAudioUnitScope_Global, 0, &player.pointee.inputFile!, UInt32(MemoryLayout<AudioFileID>.size))
        
        // some args need get to caculate duration
        var nPackets = UInt64.init()
        var propSize = UInt32(MemoryLayout<UInt64>.size)
        AudioFileGetProperty(player.pointee.inputFile!, kAudioFilePropertyAudioDataPacketCount, &propSize, &nPackets)
        
        // second tell file player to play
        let frames = UInt32(nPackets) * player.pointee.inputFormat.mFramesPerPacket
        var stamp = AudioTimeStamp.init()
        stamp.mSampleTime = 0
        stamp.mFlags = AudioTimeStampFlags.sampleTimeValid
        var rgn = ScheduledAudioFileRegion.init(mTimeStamp: stamp, mCompletionProc: nil, mCompletionProcUserData: nil, mAudioFile: player.pointee.inputFile!, mLoopCount: 1, mStartFrame: 0, mFramesToPlay: frames)
        AudioUnitSetProperty(player.pointee.fileAU!, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &rgn, UInt32(MemoryLayout<ScheduledAudioFileRegion>.size))
        
        // prime the file player AU whit default values
        var defaultVal = UInt32.init()
        AudioUnitSetProperty(player.pointee.fileAU!, kAudioUnitProperty_ScheduledFilePrime, kAudioUnitScope_Global, 0, &defaultVal, UInt32(MemoryLayout<UInt32>.size))
        
        // tell file player AU when to start playing
        var startTime = AudioTimeStamp.init()
        startTime.mFlags = AudioTimeStampFlags.sampleTimeValid
        startTime.mSampleTime = -1
        AudioUnitSetProperty(player.pointee.fileAU!, kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0, &startTime, UInt32(MemoryLayout<AudioTimeStamp>.size))
        
        // caculate duration
        return Float64(nPackets * UInt64(player.pointee.inputFormat.mFramesPerPacket)) / Float64(player.pointee.inputFormat.mSampleRate)
    }
    
}

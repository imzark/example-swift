//
//  PlayAudio.swift
//  audio
//
//  Created by harry on 2019/7/23.
//  Copyright © 2019 harry. All rights reserved.
//

import Foundation
import AudioToolbox

// MARK: user data struct
struct MyPlayer {
    var playbackFile: AudioFileID?
    var packetPosition: Int64
    var numPacketsToRead: UInt32
    var packetDescs: UnsafeMutablePointer<AudioStreamPacketDescription>?
    var isDone: Bool
    init() {
        isDone = false
        playbackFile = AudioFileID.init(bitPattern: 1)
        packetPosition = 0
        numPacketsToRead = 0
        packetDescs = nil
    }
}

// MARK: utility functions
func CheckErr(_ err: OSStatus) -> Bool {
    var isSucccess = false
    switch err {
    case noErr:
        isSucccess = true
        break;
    case kAudioFileUnspecifiedError:
        print("An unspecified error has occurred.")
    case kAudioFileUnsupportedFileTypeError:
        print("The file type is not supported.")
    case kAudioFileUnsupportedDataFormatError:
        print("The data format is not supported by this file type.")
    case kAudioFileUnsupportedPropertyError:
        print("The property is not supported.")
    case kAudioFileBadPropertySizeError:
        print("The size of the property data was not correct.")
    case kAudioFilePermissionsError:
        print("The operation violated the file permissions. For example, an attempt was made to write to a file opened with the kAudioFileReadPermission constant.")
    case kAudioFileNotOptimizedError:
        print("The chunks following the audio data chunk are preventing the extension of the audio data chunk. To write more data, you must optimize the file.")
    case kAudioFileInvalidChunkError:
        print("Either the chunk does not exist in the file or it is not supported by the file.")
    case kAudioFileDoesNotAllow64BitDataSizeError:
        print("The file offset was too large for the file type. The AIFF and WAVE file format types have 32-bit file size limits.")
    case kAudioFileInvalidPacketOffsetError:
        print("A packet offset was past the end of the file, or not at the end of the file when a VBR format was written, or a corrupt packet size was read when the packet table was built.")
    case kAudioFileInvalidFileError:
        print("The file is malformed, or otherwise not a valid instance of an audio file of its type.")
    case kAudioFileOperationNotSupportedError:
        print("The operation cannot be performed. For example, setting the \(kAudioFilePropertyAudioDataByteCount) constant to increase the size of the audio data in a file is not a supported operation. Write the data instead.")
    case kAudioFileNotOpenError:
        print("The file is closed.")
    case kAudioFileEndOfFileError:
        print("End of file.")
    case kAudioFilePositionError:
        print("Invalid file position.")
    case kAudioFileFileNotFoundError:
        print("File not found.")
    default:
        isSucccess = true
        break;
    }
    return isSucccess
}

func CheckStatus(_ status: OSStatus) -> Bool {
    if status != noErr {
        let nserror = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        print(nserror)
        return false
    }
    return true
}

func CalculateBytesForTime(_ file:AudioFileID, _ dataFormat:AudioStreamBasicDescription, _ inSeconds:Float, _ outBuffSize: UnsafeMutablePointer<UInt32>, _ outNumPackets: UnsafeMutablePointer<UInt32>) {
    var maxPacketSize:UInt32 = 1
    var propSize = UInt32(MemoryLayout<UInt32>.size)
    AudioFileGetProperty(file, kAudioFilePropertyPacketSizeUpperBound, &propSize, &maxPacketSize)
    let maxBufferSize = 0x10000
    let minBufferSize = 0x40000
    
    if dataFormat.mFramesPerPacket > 0 {
        let numPacketsForTime = Float(dataFormat.mSampleRate) / Float(dataFormat.mFramesPerPacket) * inSeconds
        outBuffSize.pointee = UInt32(numPacketsForTime) * maxPacketSize
    } else {
        outBuffSize.pointee = maxBufferSize > maxPacketSize ? UInt32(maxBufferSize) : maxPacketSize
    }
    
    if outBuffSize.pointee > maxBufferSize && outBuffSize.pointee > maxPacketSize {
        outBuffSize.pointee = UInt32(maxBufferSize)
    } else {
        if outBuffSize.pointee < minBufferSize {
            outBuffSize.pointee = UInt32(minBufferSize)
        }
    }
    outNumPackets.pointee = outBuffSize.pointee / maxPacketSize
}

func MyCopyEncoderCookieToQueue(_ file:AudioFileID, _ queue:AudioQueueRef) {
    var propertySize:UInt32 = 1
    let status = AudioFileGetPropertyInfo(file, kAudioFilePropertyMagicCookieData, &propertySize, nil)
    print("MyCopyEncoderCookieToQueue: \(CheckErr(status)); propertySize: \(propertySize)")
    if status == noErr && propertySize > 0 {
        
    }
}

// MARK: playback callback function
func MyAQOutputCallback(_ inUserData:UnsafeMutableRawPointer?, _ queue:AudioQueueRef, _ inCompleteAQBuffer:AudioQueueBufferRef) {
    let player = inUserData!.assumingMemoryBound(to: MyPlayer.self)
    if player.pointee.isDone {
        return
    }
    var numBytes:UInt32 = 0
    var nPackets = player.pointee.numPacketsToRead
    AudioFileReadPackets(player.pointee.playbackFile!, false, &numBytes, player.pointee.packetDescs, player.pointee.packetPosition, &nPackets, inCompleteAQBuffer.pointee.mAudioData)
    if nPackets > 0 {
        inCompleteAQBuffer.pointee.mAudioDataByteSize = numBytes
        let inNums = player.pointee.packetDescs != nil ? nPackets : 0
        AudioQueueEnqueueBuffer(queue, inCompleteAQBuffer, inNums, player.pointee.packetDescs)
        player.pointee.packetPosition += Int64(nPackets)
    } else {
        let status = AudioQueueStop(queue, false)
        print("AudioQueueStop: \(status)")
        player.pointee.isDone = true
    }
}


class PlayAudio {
    static func checkStatus (_ status: OSStatus) -> Bool {
        return CheckStatus(status)
    }
    static func checkError (_ status: OSStatus) -> Bool {
        return CheckErr(status)
    }
    public func start () {
        // MARK: open audio file
        var player = MyPlayer.init()
//        let url = Bundle.main.url(forResource: "test", withExtension: "mp3")!
//        print(url.absoluteString as CFString)
//        let myFileURL = url as CFURL
        let kPlaybackFileLocation = "/Users/harry/Music/test.mp3" as CFString
        let myFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, kPlaybackFileLocation, CFURLPathStyle.cfurlposixPathStyle, false)!
        let status = AudioFileOpenURL(myFileURL, AudioFilePermissions.readWritePermission, 0,  &player.playbackFile)
        print("AudioFileOpenURL: \(CheckErr(status)); myFileURL:\(String(describing: myFileURL))")
        
        // MARK: set up format
        var dataFormat = AudioStreamBasicDescription.init()
        var propSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        if player.playbackFile != nil {
            AudioFileGetProperty(player.playbackFile!, kAudioFilePropertyDataFormat, &propSize, &dataFormat)
        }
        
        // MARK: set up queue
        var queue:AudioQueueRef? = nil
        AudioQueueNewOutput(&dataFormat, MyAQOutputCallback, &player, nil, nil, 0, &queue)
        
        var bufferByteSize:UInt32 = 1
        CalculateBytesForTime(player.playbackFile!, dataFormat, 0.5, &bufferByteSize, &player.numPacketsToRead)
        
        let isFormatVBR = (dataFormat.mBytesPerPacket == 0 || dataFormat.mFramesPerPacket == 0)
        if isFormatVBR {
            let p = malloc(MemoryLayout<AudioStreamPacketDescription>.size * Int(player.numPacketsToRead))
            player.packetDescs = p?.assumingMemoryBound(to: AudioStreamPacketDescription.self)
        } else {
            player.packetDescs = nil
        }
        
        MyCopyEncoderCookieToQueue(player.playbackFile!, queue!)
        
        let kNumberPlaybackBuffers = 3
        var buffers = [AudioQueueBufferRef?](repeating: nil, count: kNumberPlaybackBuffers)
        player.isDone = false
        player.packetPosition = 0
        
        for i in 0..<kNumberPlaybackBuffers {
            AudioQueueAllocateBuffer(queue!, bufferByteSize, &buffers[i])
            MyAQOutputCallback(&player, queue!, buffers[i]!)
            if player.isDone {
                break
            }
        }
        
        // MARK: start queue
        let s = AudioQueueStart(queue!, nil)
        print("Playing...\n\(CheckErr(s))\n")
        
        repeat {
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.25, false)
        } while !player.isDone
        
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 5, false);
        
        // MARK: clean up when playback finished
        player.isDone = true
        AudioQueueStop(queue!, true)
        AudioQueueDispose(queue!, true)
        AudioFileClose(player.playbackFile!)
        print("stop.")
    }
}


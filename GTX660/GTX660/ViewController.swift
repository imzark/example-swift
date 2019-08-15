//
//  ViewController.swift
//  GTX660
//
//  Created by Harry Tang on 2019/6/3.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

import Cocoa
import AVFoundation
import MetalKit
import CoreImage

class ViewController: NSViewController {
	@IBOutlet weak var player: NSImageView!
	
	var frames: [VideoFrame] = []
//	var pcms: [] = []
	var dirs:[Double] = []
	var pixelBufferPool: CVPixelBufferPool? = nil
	var pixelBuffer:CVPixelBuffer? = nil
	
	var bufferedDuration: Double = 0
	var minBufferedDuration: Double = 0.2
	var maxBufferedDuration: Double = 0.6
	var iinii = false;
	
	override func viewDidLoad() {
		super.viewDidLoad()
		DispatchQueue.global().sync {
			self.open()
		}
	}
	
	func open() {
		let uri = "/Users/harry/Desktop/videos/a-asdasd-123.mp4";
		if VideoDecoder.shared.start(uri) {
      DispatchQueue.main.asyncAfter(deadline: .now()+0.1 , execute: {
        DispatchQueue.global().async {
          VideoDecoder.shared.decode(1)
        }
      })
      DispatchQueue.main.asyncAfter(deadline: .now()+1.1 , execute: {
        self.trik()
      })
		}
	}
	
//  func decode() {
//    let uri = "http://127.0.0.1:8080/friends.s01e01.720p.bluray.x264.AAC-iHD.mp4";
//    if VideoDecoder.shared.start(uri) {
//      DispatchQueue.main.asyncAfter(deadline: .now()+0.01 , execute: {
//        VideoDecoder.shared.setAudio()
//        DispatchQueue.global().async {
//          while !VideoDecoder.shared.isEOF {
//            let vf = VideoDecoder.shared.decode(self.maxBufferedDuration)
//            for i in 0..<vf.count {
//              self.frames.append(vf[i])
//              self.bufferedDuration += vf[i].duration;
//            }
//
//            if self.bufferedDuration > self.maxBufferedDuration {
//              break
//            }
//          }
//        }
//      })
//      DispatchQueue.main.asyncAfter(deadline: .now()+1.1 , execute: {
//        self.trik()
//      })
//    }
//  }
	
	func getFrames()  {
		if VideoDecoder.shared.opened {
			while !VideoDecoder.shared.isEOF {
				let vf = VideoDecoder.shared.decode(0.2)
				for i in 0..<vf.count {
					self.frames.append(vf[i])
					bufferedDuration += vf[i].duration;
				}
				
				if bufferedDuration > maxBufferedDuration {
					break
				}
			}
		}
	}
	
	
	override var representedObject: Any? {
		didSet {
			// Update the view, if already loaded.
		}
	}
	
	func trik() {
//		print(frames.count, bufferedDuration)
		if frames.count <= 0 {
//			print("get1")
			self.getFrames()
			return
		}
		let interval = render()
		if bufferedDuration < minBufferedDuration {
//			print("get2")
			self.getFrames()
		}
		let time = max(interval, 0.01)
		print(interval, time)
		DispatchQueue.main.asyncAfter(deadline: .now()+time, execute: {
			self.trik()
		})
	}
	
	
	private func render() -> Double {
		let vf = frames.remove(at: 0)
		bufferedDuration -= vf.duration
		let cm = CIImage.init(cvPixelBuffer: vf.buffer!)
		let rep = NSCIImageRep(ciImage: cm)
		let nsImage = NSImage(size: rep.size)
		nsImage.addRepresentation(rep)
		player.image = nsImage
		return vf.duration
	}
	
	func f2i(in vf: VideoFrame) -> NSImage {
		
		var attributes: [AnyHashable : Any] = [:]
		attributes[kCVPixelBufferPixelFormatTypeKey as String] = NSNumber(value: Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange))
		attributes[kCVPixelBufferWidthKey as String] = NSNumber(value: vf.width)
		attributes[kCVPixelBufferHeightKey as String] = NSNumber(value: vf.height)
		attributes[kCVPixelBufferBytesPerRowAlignmentKey as String] = NSNumber(value: vf.linesize)
		attributes[kCVPixelBufferIOSurfacePropertiesKey as String] = [AnyHashable : Any]()
		let theError = CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attributes as CFDictionary, &pixelBufferPool)
		if theError != kCVReturnSuccess {
			print("CVPixelBufferPoolCreate Failed")
		}
		
		let theError1 = CVPixelBufferPoolCreatePixelBuffer(nil, self.pixelBufferPool!, &pixelBuffer);
		if theError1 != kCVReturnSuccess {
			print("CVPixelBufferPoolCreatePixelBuffer Failed")
		}
		
		CVPixelBufferLockBaseAddress(pixelBuffer!, [])
		let bytePerRowY: Int = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer!, 0)
		let bytesPerRowUV: Int = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer!, 1)
		var base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 0)
		if vf.frame!.data.0 != nil {
			memcpy(base, vf.frame!.data.0, bytePerRowY *  Int(vf.height))
		}
		base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 1)
		if vf.frame!.data.1 != nil {
			memcpy(base, vf.frame!.data.1, bytesPerRowUV *  Int(vf.height) / 2)
		}
		CVPixelBufferUnlockBaseAddress(pixelBuffer!, [])
		let cm = CIImage.init(cvPixelBuffer: pixelBuffer!)
		let rep = NSCIImageRep(ciImage: cm)
		let nsImage = NSImage(size: rep.size)
		nsImage.addRepresentation(rep)
		return nsImage
	}
	
}

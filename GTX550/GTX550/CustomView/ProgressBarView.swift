//
//  ProgressBarView.swift
//  GTX550
//
//  Created by Harry Tang on 2019/6/14.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

import Cocoa

typealias ProgressCallback = (_ seek: Double) -> Bool

@IBDesignable
class ProgressBarView: NSView {
	
	override var mouseDownCanMoveWindow: Bool {
		get {
			return false
		}
	}
	private var trackingArea: NSTrackingArea?
	
	override func updateTrackingAreas() {
		super.updateTrackingAreas()
		
		if let trackingArea = self.trackingArea {
			self.removeTrackingArea(trackingArea)
		}
		
		let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
		let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
		self.addTrackingArea(trackingArea)
	}
	
	@IBInspectable
	var backgroundColor: NSColor = NSColor.white {
		didSet {
			layer?.backgroundColor = self.backgroundColor.cgColor
		}
	}
	var handleSeek: ProgressCallback!
	
	@IBInspectable
	var value:Double = 0.0 {
		didSet {
			if !self.isDrag {
				render()
			}
		}
	}
	
	private var dragValue: Double = 0.0
	
	private var isDrag: Bool = false
	
	private var progressView: NSView = NSView.init()
	
	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)
		progressView.wantsLayer = true
		progressView.layer?.backgroundColor = NSColor.green.cgColor
		self.wantsLayer = true
		addSubview(progressView)
		render()
	}
	
	func render() {
		let prec = CGFloat.init(value / 100) * self.bounds.width
		progressView.frame = NSRect.init(x: 0 as CGFloat, y: 0 as CGFloat, width: prec, height: self.bounds.height)
	}
	
	
	override func mouseEntered(with event: NSEvent) {
//		print("mouseEntered")
//		value += 1.0
//		self.layer?.backgroundColor = NSColor.yellow.cgColor
	}
	
	override func mouseExited(with event: NSEvent) {
	}
	
	override func mouseDown(with event: NSEvent) {
		isDrag = true
		dragValue = value
//		print(event.scrollingDeltaX)
	}
	
	override func mouseDragged(with event: NSEvent) {
//		print("drag")
		let dis = (event.deltaX / self.bounds.width) * 100
		dragValue += Double(dis)
		if dragValue > 100 {
			dragValue = 100
		} else if dragValue < 0 {
			dragValue = 0
		}
		
		let prec = CGFloat.init(dragValue / 100) * self.bounds.width
		progressView.frame = NSRect.init(x: 0 as CGFloat, y: 0 as CGFloat, width: prec, height: self.bounds.height)
	}
	
	override func mouseUp(with event: NSEvent) {
//		print(event.scrollingDeltaX)
		handleSeek!(dragValue)
		DispatchQueue.main.asyncAfter(deadline:	.now() + 0.1) {
			self.isDrag = false
		}
	}
}

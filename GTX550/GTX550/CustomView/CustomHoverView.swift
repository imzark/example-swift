//
//  CustomHoverView.swift
//  GTX550
//
//  Created by Harry Tang on 2019/6/12.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

import Cocoa

class CustomHoverView: NSView {
	
	var backgroundColor: NSColor = NSColor.black
	var hoveredBackgroundColor: NSColor = NSColor.black
	var handleLeftClick = {}
	var didMouseDown: Bool = false

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
	
	override var wantsUpdateLayer:Bool{
		return true
	}
	
	override func mouseEntered(with event: NSEvent) {
		self.layer?.backgroundColor = hoveredBackgroundColor.cgColor
	}
	
	override func mouseExited(with event: NSEvent) {
		self.layer?.backgroundColor = backgroundColor.cgColor
	}
	
	override func mouseDown(with event: NSEvent) {
		didMouseDown = true
	}
	override func mouseUp(with event: NSEvent) {
		if didMouseDown {
			handleLeftClick()
		}
		didMouseDown = false
	}
}

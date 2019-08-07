//
//  MoveableView.swift
//  GTX550
//
//  Created by Harry Tang on 2019/6/14.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

import Cocoa

class MoveableView: NSView {
	
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		// Drawing code here.
	}
	
	override var mouseDownCanMoveWindow: Bool {
		get {
			return true
		}
	}
}

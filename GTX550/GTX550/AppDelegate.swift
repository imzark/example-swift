//
//  AppDelegate.swift
//  GTX550
//
//  Created by Harry Tang on 2019/6/10.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		// window可以拖拽
		NSApp.mainWindow?.isMovableByWindowBackground = true
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}


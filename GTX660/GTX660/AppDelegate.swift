//
//  AppDelegate.swift
//  GTX660
//
//  Created by Harry Tang on 2019/6/3.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	var mainWindowController: PlayerWindow?

	@IBOutlet weak var statusMenu: NSMenu!
	var statusBar = NSStatusBar.system
	var statusBarItem: NSStatusItem = NSStatusItem.init()
	
	override func awakeFromNib() {
		statusBarItem = statusBar.statusItem(withLength: -1)
		statusBarItem.menu = statusMenu
//		statusBarItem.button?.image = NSImage.init(named: "NN")
		statusBarItem.button?.imagePosition = NSControl.ImagePosition.imageLeft
		statusBarItem.button?.title="2"
	}

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	@IBAction func openLocalVideo(_ sender: Any) {
		let storyboard:NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
		guard let controller:NSWindowController = storyboard.instantiateController(withIdentifier: "PlayerWindow") as? PlayerWindow else { return /*or handle error*/ }
		controller.showWindow(self)
	}
	
	@IBAction func openYouTube(_ sender: Any) {
		let storyboard:NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
		guard let controller:NSWindowController = storyboard.instantiateController(withIdentifier: "PlayerWindow") as? PlayerWindow else { return /*or handle error*/ }
		controller.showWindow(self)
	}
}


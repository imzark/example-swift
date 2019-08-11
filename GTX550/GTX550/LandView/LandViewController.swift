//
//  LandViewController.swift
//  GTX550
//
//  Created by Harry Tang on 2019/6/12.
//  Copyright © 2019 Harry Tang. All rights reserved.
//

import Cocoa

class LandViewController: NSViewController {
	
	@IBOutlet weak var openFileButton: CustomHoverView!
	@IBOutlet weak var openURLButton: CustomHoverView!
	
	var player: AudioPlayer = AudioPlayer()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.window?.isMovableByWindowBackground = true
		openURLButton.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0)
		openFileButton.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0)

		openFileButton.handleLeftClick = {
			let openPanel:NSOpenPanel = NSOpenPanel()
			// 是否可以选择文件夹
			openPanel.canChooseDirectories = false
			// 是否可以选择文件
			openPanel.canChooseFiles = true
			// 是否可以多选
			openPanel.allowsMultipleSelection = true
			// 设置可选文件后缀名
			openPanel.allowedFileTypes=["mp4", "mp3", "wav", "aac", "pcm", "mkv"]
			
			openPanel.beginSheetModal(for: NSApp.mainWindow!) { (result) in
				if result.rawValue == NSFileHandlingPanelOKButton {
					if openPanel.urls.count > 1 {
						
					} else if openPanel.urls.count == 1 {
						// 打开单个文件
					}
//					let storyboard = NSStoryboard(name: "Main", bundle: nil)
//
//					guard let playView = storyboard.instantiateController(withIdentifier: "PlayViewController") as? PlayViewController else {
//						fatalError("Error getting main window controller")
//					}
//					playView.url = openPanel.urls[0].absoluteString
//					NSApp.mainWindow?.contentViewController = playView
					
					self.player.start(openPanel.urls[0].absoluteString)
					self.player.play()
					self.player.play()
				}
			}
		}
	}
}



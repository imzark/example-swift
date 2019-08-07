//
//  ChannelTableCellView.swift
//  slide
//
//  Created by harry on 2019/8/7.
//  Copyright © 2019 harry. All rights reserved.
//

import Cocoa

class ChannelTableCellView: NSTableCellView {

  @IBOutlet weak var image: NSButton!
  @IBOutlet weak var label: NSTextField!
  
  override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}

//
//  HomeViewController.swift
//  slide
//
//  Created by harry on 2019/8/7.
//  Copyright © 2019 harry. All rights reserved.
//

import Cocoa

struct ChannelData {
  var label: String
  var image: NSImage
}

class HomeViewController: NSViewController, NSTableViewDataSource {
  
  var channels: [ChannelData] = [
    ChannelData(label: "YouTube", image: #imageLiteral(resourceName: "youtube_social_circle_white")),
    ChannelData(label: "YouTube", image: #imageLiteral(resourceName: "youtube_social_circle_white"))
  ]
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
  }
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return channels.count
  }
  
  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    let id = NSUserInterfaceItemIdentifier(rawValue: "ChannelTableCellView")
    print(id)
    let cell = tableView.makeView(withIdentifier: id, owner: self)
    print(cell)
    
    var c = cell as! ChannelTableCellView
    
    c.image.image = channels[row].image
    c.label.stringValue = channels[row].label
    
    return c
  }
  
}

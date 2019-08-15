//
//  ViewController.swift
//  ff
//
//  Created by harry on 2019/8/13.
//  Copyright © 2019 harry. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    open()
  }
  
  
  func open() {
    let uri = "/Users/harry/Desktop/videos/越狱SE01.H265.1070P.02.mkv";
    if Decoder.shared.start(uri) {
      DispatchQueue.main.asyncAfter(deadline: .now()+0.1 , execute: {
        DispatchQueue.global().async {
          Decoder.shared.decode(1)
        }
      })
      DispatchQueue.main.asyncAfter(deadline: .now()+1.1 , execute: {
//        self.trik()
      })
    }
  }
}


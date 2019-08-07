//
//  ViewController.swift
//  audio
//
//  Created by harry on 2019/7/23.
//  Copyright © 2019 harry. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let p = PlayAL.init()
        p.start()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}


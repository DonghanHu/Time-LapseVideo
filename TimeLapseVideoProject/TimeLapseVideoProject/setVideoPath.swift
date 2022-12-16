//
//  setVideoPath.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 12/16/22.
//  Copyright © 2022 Donghan Hu. All rights reserved.
//

import Cocoa

extension setVideoPath {
    convenience init() {
        self.init(windowNibName: .init("setVideoPath"))
    }
}

class setVideoPath: NSWindowController {

    @IBOutlet weak var setFolderPathButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.title = "Preference Setting"

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func setFolderPathAction(_ sender: Any) {
        print("set video saved path button is clicked")
        
    }
}

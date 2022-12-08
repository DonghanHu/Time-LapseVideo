//
//  videoWatchWindow.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 12/8/22.
//  Copyright © 2022 Donghan Hu. All rights reserved.
//

import Cocoa
import AVKit

extension videoWatchWindow {
    convenience init() {
        self.init(windowNibName: .init("videoWatchWindow"))
    }
}

class videoWatchWindow: NSWindowController{
    
    
    override func windowDidLoad() {
        super.windowDidLoad()

        print("watch time-lapse video window")

        
        let settings = RenderSettings()
        let imageAnimator = ImageAnimator(renderSettings: settings)
        imageAnimator.render() {
            print("yes")
        }
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}

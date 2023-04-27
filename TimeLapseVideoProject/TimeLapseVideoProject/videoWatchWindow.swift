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
    
    @IBOutlet weak var fameRateField: NSTextField!
    @IBOutlet weak var captureIntervalField: NSTextField!

    @IBOutlet weak var captureIntervalLabel: NSTextField!
    @IBOutlet weak var frameRateLabel: NSTextField!
    @IBOutlet weak var confirmButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        print("watch time-lapse video window")
        confirmButton.title = "Setting"
        
        fameRateField.stringValue = String(Setting.frameRate)
        captureIntervalField.stringValue = String(Setting.captureInterval)
        
        frameRateLabel.stringValue = "Frame rate should be within 5 and 30 for higher video quality"
        captureIntervalLabel.stringValue = "Captuer Interval should be within 5 and 15 for taking enough photos"
        
//        let settings = RenderSettings()
//        let imageAnimator = ImageAnimator(renderSettings: settings)
//        imageAnimator.render() {
//            print("yes")
//        }
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func comfirmButtonAction(_ sender: Any) {
        print("confirm button is clicked!")
        print(fameRateField.stringValue)
        print(captureIntervalField.stringValue)
        let tempFrameRate = Int(fameRateField.stringValue) ?? 12
        let tempCaptureInterval = Int(captureIntervalField.stringValue) ?? 10
        
        if(tempFrameRate < 5 || tempFrameRate > 30){
            let alert = NSAlert()
            alert.messageText = "Invalide frame rate"
            alert.informativeText = "Please input frame rate between 5 and 30"
            let result = alert.runModal()
        } else{
            Setting.frameRate = tempFrameRate
        }
        if(tempCaptureInterval < 5 || tempFrameRate > 15){
            let alert = NSAlert()
            alert.messageText = "Invalide capture interval"
            alert.informativeText = "Please input frame rate between 5 and 15"
            let result = alert.runModal()
        } else{
            Setting.captureInterval = tempCaptureInterval
        }
        
        print(Setting.frameRate)
        print(Setting.captureInterval)
    }
    
}

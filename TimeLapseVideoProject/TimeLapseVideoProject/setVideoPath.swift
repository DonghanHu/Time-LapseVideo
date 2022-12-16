//
//  setVideoPath.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 12/16/22.
//  Copyright © 2022 Donghan Hu. All rights reserved.
//

import Cocoa
import AppKit

extension setVideoPath {
    convenience init() {
        self.init(windowNibName: .init("setVideoPath"))
    }
}

class setVideoPath: NSWindowController {

    @IBOutlet weak var setFolderPathButton: NSButton!
    
    @IBOutlet weak var folderPathLabel: NSTextField!
    
    @IBOutlet weak var okDoNothingButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.title = "Preference Setting"

        okDoNothingButton.title = "OK"
        
        setFolderPathButton.title = "Change"
        
        folderPathLabel.stringValue = Repository.downloadingVideosFolderPathString
        
        
        let button = NSButton(frame: NSRect(x: 150, y: 200, width: 80, height: 55))
        button.title =  "A button in code"
        
        button.target = self
        button.action = #selector(buttonTest)
        self.window?.contentView?.addSubview(button)
        
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func okDoNothingAction(_ sender: Any) {
        print("clicked OK button")
        self.window?.close()
    }
    
    @objc func buttonTest(sender: NSButton!)  {
        do {
            try? print("Test button")
        }
        catch{
            print(Error.self)
        }
        
    }
    
    // click button with "change" title
    @IBAction func setFolderPathAction(_ sender: Any) {
        
        print("set video saved path button is clicked")
        
        // open a panel to choose disternation folder for saving videos
        let panel = NSOpenPanel()
        var folderPath = "FolderPath"
        let defaultErrorString = "empty url for folder path"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if (panel.runModal() ==  NSApplication.ModalResponse.OK) {
            folderPath = panel.url?.absoluteString ?? defaultErrorString
            
            print("final path is set as: " + folderPath)
            if(folderPath != defaultErrorString){
                alertDialogClass().confirmIsReady(question: "Q", text: "T")
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    
}

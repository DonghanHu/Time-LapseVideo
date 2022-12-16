//
//  folderSelector.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 12/16/22.
//  Copyright © 2022 Donghan Hu. All rights reserved.
//

import Foundation
import AppKit


class alertDialogClass{
    
    func confirmIsReady(question: String, text: String){
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "OK")
        // alert.addButton(withTitle: "Cancel")
        
        // run modal to display this alert dialog
        alert.runModal()
        
        // return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }
    
}

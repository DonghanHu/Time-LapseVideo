//
//  ScreenshotInfo.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 12/7/22.
//  Copyright © 2022 Donghan Hu. All rights reserved.
//

import Foundation

// class for per screenshot taken during recording
class ScreenshotInfor{
    var screenshotName: String
    var screenshotDate: String
    
    init(name: String, date: String){
        self.screenshotName = name
        self.screenshotDate = date
    }
}

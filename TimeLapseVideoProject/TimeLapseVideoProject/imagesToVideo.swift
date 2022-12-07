//
//  imagesToVideo.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 12/7/22.
//  Copyright © 2022 Donghan Hu. All rights reserved.
//

import Foundation

// class to transfer images to a video
class imagesToVideo{
    
    // check wether a target folder with specific date exists or not
    // @return boolen result
    func hasFolderBasedOnDate(year: String, month: String, day: String) -> Bool{
        let targetFolderDate = month + "-" + day + "-" + year
        let targetFolderPath = Repository.defaultFolderPathString + targetFolderDate
        if FileManager.default.fileExists(atPath: targetFolderDate){
            return true
        }
        else{
            return false
        }
    }
    
    // load screenshots from a folder
    func loadScreenshots(folderPath: String) -> [CGImage]{
        var imagesArray : [CGImage]!
        
        
        return imagesArray
    }
    
    
}

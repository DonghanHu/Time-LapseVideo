//
//  takeScreenshot.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 12/7/22.
//  Copyright © 2022 Donghan Hu. All rights reserved.
//

import Foundation

class takeScreenshots{
    
    var tempFolderPathString: String!
    
    // return current year
    func getCurrentYear() -> String{
        let date = Date()
        let calendar = NSCalendar.current
        let year = calendar.component(.year, from: date)
        return String(year)
    }
    // return current month
    func getCurrentMonth() -> String{
        let date = Date()
        let calendar = NSCalendar.current
        let month = calendar.component(.month, from: date)
        return String(month)
    }
    // return current day
    func getCurrentDay() -> String{
        let date = Date()
        let calendar = NSCalendar.current
        let day = calendar.component(.day, from: date)
        return String(day)
    }
    
    // check and creat folder for saving screenshots
    func creatFolderForTodayRecording(){
        let currentDate = getCurrentMonth() + "-" + getCurrentDay() + "-" + getCurrentYear()
        let newRecordingFolderPath = Repository.defaultFolderPathString + currentDate
        print("screenshot folder name is: " + newRecordingFolderPath)
        
        tempFolderPathString = newRecordingFolderPath
        
        Repository.dailyScreenshotFolderString = newRecordingFolderPath
        
        if(FileManager.default.fileExists(atPath: newRecordingFolderPath)){
            print("default folder for today's screenshots is already existed!")
        }
        else{
            do {
                try FileManager.default.createDirectory(atPath: newRecordingFolderPath, withIntermediateDirectories: true, attributes: nil)
            } catch{
                print("screenshot's folder created failed!")
                print(error)
            }
        }
    }
    
    // return today's folder path
    func returnCurrentFolder() -> String{
        let currentDate = getCurrentMonth() + "-" + getCurrentDay() + "-" + getCurrentYear()
        let newRecordingFolderPath = Repository.defaultFolderPathString + currentDate
        return newRecordingFolderPath
        
    }
    
    // function to take a screenshot with customsized arguments with formatted date name
    func takeANewScreenshotWithFormattedDateName(){
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY.MM.dd,HH-mm-ss"
        let dateString = dateFormatter.string(from: date)
        
        
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        var arguments = [String]();
        arguments.append("-x")
        
        let tempScreenshotPerPathString = tempFolderPathString + "/" + dateString + ".jpg"
        arguments.append(tempScreenshotPerPathString)
        
        print("screenshot path: " + tempScreenshotPerPathString)
        
        task.arguments = arguments
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        task.standardError = outpipe
        
        do {
            try task.run()
            
        } catch {
            print("failed in taking a new screenshot")
            print(error)
        }
        
        // wait until task is finished and exit
        task.waitUntilExit()
        
    }
    
    // function to take a screenshot with increasing counter in names based changing daily
    func takeANewScreenshotWithIncreadingCounter(){
        // get  current date
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"
        let dateString = dateFormatter.string(from: date)
        
        // generate new file name with "FRAME" ahead as an identifier
        // add counter indicating order

        let counterString = String(format: "%08d", DailyCounter.counter)
        let screenshotName = "FRAME" + String(DailyCounter.counter)
        
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        var arguments = [String]();
        arguments.append("-x")
        
        let tempScreenshotPerPathString = tempFolderPathString + "/" + dateString + ".jpg"
        arguments.append(tempScreenshotPerPathString)
        
        print("screenshot path: " + tempScreenshotPerPathString)
        
        task.arguments = arguments
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        task.standardError = outpipe
        
        do {
            try task.run()
            
        } catch {
            print("failed in taking a new screenshot")
            print(error)
        }
        
        // wait until task is finished and exit
        task.waitUntilExit()
        
        // increase the default counter: + 1
        DailyCounter.counter = DailyCounter.counter + 1
        
    }
    
    
}

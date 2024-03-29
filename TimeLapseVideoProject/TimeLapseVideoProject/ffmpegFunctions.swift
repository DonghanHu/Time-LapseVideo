//
//  ffmpegFunctions.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 1/9/23.
//  Copyright © 2023 Donghan Hu. All rights reserved.
//

import Foundation


// ffmpeg example: To convert such a list into an mp4, at 24 frames per second we can navigate in the terminal to the directory containing our images and then write:

// ffmpeg -r 24 -f image2 -pattern_type glob -i "*?png" -vcodec libx264 -crf 20 -pix_fmt yuv420p output.mp4

// functions using ffmpeg
class ffmpegClass {
    
    
    
    // ffmpeg -r 24 -f image2 -pattern_type glob -i "*?jpg" -vcodec libx264 -crf 20 -pix_fmt yuv420p output.mp4
    
    func basicFunction(inputFilePath: String, outputFilePath: String) {
        guard let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else{
            print("error in ffmpeg launch path")
            return
        }
        
        
        let process = Process()
        
        // print("currentDirectoryURL: " + inputFilePath)
        print("current: " + process.currentDirectoryPath)
        print(URL(string: inputFilePath))
        print(URL(string: inputFilePath)?.absoluteString)
        // process.currentDirectoryURL = URL(string: inputFilePath)
        print("current: " + process.currentDirectoryPath)
        process.launchPath = launchPath
        //process.launchPath = "/usr/local/bin/ffmpeg"
        
        // /usr/local/bin/ffmpeg -r 24 -f image2 -pattern_type glob -i "Desktop/ScreenshotsForVideos/*?jpg" -vcodec libx264 -crf 20 -pix_fmt yuv420p Downloads/output1.mp4
        // let imageInputPath = Repository.dailyScreenshotFolderString + "\"*?jpg\""
        // let imageOutputPath = Repository.downloadingVideosFolderPathString + "tempName.mp4"
        let imageInputPath = "\"./ScreenshotsForVideos/*?jpg\""
        let imageOutputPath = "./Downloads/output.mp4"
        // /Users/donghanhu/Downloads/output.mp4
        
//        print("input file path: " + imageInputPath)
//        print("output file path: " + imageOutputPath)
        
        // process.launchPath = "/bin/pwd"
        
        // process.arguments = ["-version"]
//        process.arguments = [
//            "-i", inputFilePath,
//            "-r", "10", "-f", "image2", "-pattern_type", "glob",
//            "-vcodec", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
//            "timekapseVideo.mp4", outputFilePath
//        ]
        
        // /Users/donghanhu/Desktop/ScreenshotsForVideos/Frame00000151.jpg
        
        let imagesFolderPath = inputFilePath + "/*?jpg"
        
//        process.arguments = [
//            "-r", "24", "-f", "image2", "-pattern_type", "glob", "-i", "/Users/donghanhu/Desktop/ScreenshotsForVideos/*?jpg",
//            "-vcodec", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
//            "/Users/donghanhu/Downloads/output2.mp4"
//
//        ]
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM.dd,HH-mm-ss"
        let dateString = dateFormatter.string(from: date)
        
        
        // new name format of genearted Time-lapse videos
        let dateFormattermmddyyyy = DateFormatter()
        dateFormattermmddyyyy.dateFormat = "MMddyyyy"
        let dateStringmmddyyyy = dateFormattermmddyyyy.string(from: date)
        
        let createdVideoName = "TimeLapseVideo" + dateString + ".mp4"
        let createdVideoFilePath = outputFilePath + createdVideoName
        
        let outputFileName = outputFilePath + "output" + dateString + ".mp4"
        let frameRateString = String(Setting.frameRate)
        // with old time-lapse video name
//        process.arguments = ["-r", frameRateString, "-f", "image2", "-pattern_type", "glob", "-i", imagesFolderPath,
//                             "-vcodec", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
//                             outputFileName]
        // name start with "TimeLapseVideo"
        process.arguments = ["-r", frameRateString, "-f", "image2", "-pattern_type", "glob", "-i", imagesFolderPath,
                                     "-vcodec", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
                             createdVideoFilePath]
        // original one
//        process.arguments = [
//            "-r", "12", "-f", "image2", "-pattern_type", "glob", "-i", imagesFolderPath,
//            "-vcodec", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
//            outputFileName
//        ]
        //print("\"*?jpg\"")

        print(process.arguments)
        process.standardInput = FileHandle.nullDevice
        process.launch()
        
        process.waitUntilExit()
        
        print("video done")
    }
    
    
    // create a new video with temporary name
    func createTimeLapseVideoWithTempName(inputFilePath: String, outputFilePath: String) {
        guard let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else{
            print("error in ffmpeg launch path")
            return
        }
        let process = Process()
        
        print("current: " + process.currentDirectoryPath)
        print(URL(string: inputFilePath))
        print(URL(string: inputFilePath)?.absoluteString)
        print("current: " + process.currentDirectoryPath)
        process.launchPath = launchPath

        
        let imagesFolderPath = inputFilePath + "/*?jpg"

        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM.dd,HH-mm-ss"
        let dateString = dateFormatter.string(from: date)
        
        
        // new name format of genearted Time-lapse videos
        let dateFormattermmddyyyy = DateFormatter()
        dateFormattermmddyyyy.dateFormat = "MMddyyyy"
        let dateStringmmddyyyy = dateFormattermmddyyyy.string(from: date)
        
        let createdVideoName = "Temp" + dateString + ".mp4"
        let createdVideoFilePath = outputFilePath + createdVideoName
        
        let outputFileName = outputFilePath + "output" + dateString + ".mp4"
        
        let frameRateString = String(Setting.frameRate)
        process.arguments = ["-r", frameRateString, "-f", "image2", "-pattern_type", "glob", "-i", imagesFolderPath,
                             "-vcodec", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
                             createdVideoFilePath]

        print(process.arguments)
        process.standardInput = FileHandle.nullDevice
        process.launch()
        
        process.waitUntilExit()
        
        print("temp video is done")
    }
    
    // create a new video with "temp" name and overwrite if file existed
    func createAndOverwriteTimeLapseVideoWithTempName(inputFilePath: String, outputFilePath: String) {
        guard let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else{
            print("error in ffmpeg launch path")
            return
        }
        let process = Process()
        
        process.launchPath = launchPath

        
        let imagesFolderPath = inputFilePath + "/*?jpg"

        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM.dd,HH-mm-ss"
        let dateString = dateFormatter.string(from: date)
        
        
        // new name format of genearted Time-lapse videos
        let dateFormattermmddyyyy = DateFormatter()
        dateFormattermmddyyyy.dateFormat = "MMddyyyy"
        let dateStringmmddyyyy = dateFormattermmddyyyy.string(from: date)
        
        let createdVideoName = "Temp" + dateString + ".mp4"
        let createdVideoFilePath = outputFilePath + createdVideoName
        
        let outputFileName = outputFilePath + "output" + dateString + ".mp4"
        
        let frameRateString = String(Setting.frameRate)
        process.arguments = ["-y", "-r", frameRateString, "-f", "image2", "-pattern_type", "glob", "-i", imagesFolderPath,
                             "-vcodec", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
                             createdVideoFilePath]

        print(process.arguments)
        process.standardInput = FileHandle.nullDevice
        process.launch()
        
        process.waitUntilExit()
        
        print("temp video is done")
    }
    
    // create a new video and overwrite if file existed
    func createAndOverwriteTimeLapseVideo(inputFilePath: String, outputFilePath: String) {
        guard let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else{
            print("error in ffmpeg launch path")
            return
        }
        let process = Process()
        
        process.launchPath = launchPath

        
        let imagesFolderPath = inputFilePath + "/*?jpg"
//
        let date = Date()
        print(date)
        // new name format of genearted Time-lapse videos
        let dateFormattermmddyyyy = DateFormatter()
        dateFormattermmddyyyy.dateFormat = "MMddyyyy"
        let dateStringmmddyyyy = dateFormattermmddyyyy.string(from: date)
        print(dateStringmmddyyyy)
        let createdVideoName = "TimeLapseVideo" + dateStringmmddyyyy + ".mp4"
        let createdVideoFilePath = outputFilePath + createdVideoName
        
        // let outputFileName = outputFilePath + "output" + dateString + ".mp4"
        
        let frameRateString = String(Setting.frameRate)
        process.arguments = ["-y", "-r", frameRateString, "-f", "image2", "-pattern_type", "glob", "-i", imagesFolderPath,
                             "-vcodec", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
                             createdVideoFilePath]

        print(process.arguments)
        process.standardInput = FileHandle.nullDevice
        process.launch()
        
        process.waitUntilExit()
        
        print("temp video is done")
    }
    
    // create video for past folders with corresponding names
    func createAndOverwriteTimeLapseVideoForPastDate(scrFolderName: String, inputFilePath: String, outputFilePath: String) {
        guard let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else{
            print("error in ffmpeg launch path")
            return
        }
        let process = Process()
        
        process.launchPath = launchPath

        let imagesFolderPath = inputFilePath + "/*?jpg"
//
        let date = Date()
    
        // new name format of genearted Time-lapse videos
        let dateFormattermmddyyyy = DateFormatter()
        dateFormattermmddyyyy.dateFormat = "MMddyyyy"
        let dateStringmmddyyyy = dateFormattermmddyyyy.string(from: date)
        
        // srcFolderName format: xx-xx-xxxx
        let dateComponents = scrFolderName.components(separatedBy: "-")
        var month = dateComponents[0]
        var day = dateComponents[1]
        var year = dateComponents[2]
        if (month.count < 2){
            month = "0" + month
        }
        if(day.count < 2) {
            day = "0" + day
        }
        
        let pastDateString = month + day + year
        
        let createdVideoName = "TimeLapseVideo" + pastDateString + ".mp4"
        let createdVideoFilePath = outputFilePath + createdVideoName
        
        // let outputFileName = outputFilePath + "output" + dateString + ".mp4"
        
        let frameRateString = String(Setting.frameRate)
        process.arguments = ["-y", "-r", frameRateString, "-f", "image2", "-pattern_type", "glob", "-i", imagesFolderPath,
                             "-vcodec", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
                             createdVideoFilePath]

        print(process.arguments)
        process.standardInput = FileHandle.nullDevice
        process.launch()
        
        process.waitUntilExit()
        
        print("temp video is done")
    }
    
    func stitchTwoVideoSideBySide(firstFilePath: String, secondFilePath: String, outputFilePath: String){
        // ffmpeg -i /Users/donghanhu/Downloads/test1.mp4 -i /Users/donghanhu/Downloads/test2.mp4 -filter_complex "concat=n=2" /Users/donghanhu/Downloads/test3.mp4
        
        guard let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else{
            print("error in ffmpeg launch path")
            return
        }
        let process = Process()
        process.launchPath = launchPath
        
        process.arguments = ["-i", firstFilePath, "-i", secondFilePath, "-filter_complex", "concat=n=2",
                             outputFilePath]

        process.standardInput = FileHandle.nullDevice
        process.launch()
        
        process.waitUntilExit()
        
        print("stitch videos is done")

        
    }
    
    
    // return a process and dispatchWorkItem, code this later
    // callback: @escaping (Bool) -> Void) -> (Process, DispatchWorkItem)?
    func generateTimeLapseVideo(inputFilePath: String, outputFilePath: String)
                      {
        
        // set ffmpeg terminal code: launch path
        guard let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else {
            return
        }
        
        let process = Process()
        // ffmpeg -r 24 -f image2 -pattern_type glob -i "*?png" -vcodec libx264 -crf 20 -pix_fmt yuv420p output.mp4
        let task = DispatchWorkItem {
            process.launchPath = launchPath
            process.arguments = [
                "-i", inputFilePath,
                "-r", "10", "-f", "image2", "-pattern_type", "glob",
                "-vcodec", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
                "timekapseVideo.mp4", outputFilePath
            ]
            // print(process.arguments)
            process.standardInput = FileHandle.nullDevice
            process.launch()
//            process.terminationHandler = { process in
//                callback(process.terminationStatus == 0)
//            }
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: task)
        
        // return (process, task)
    }
    
    typealias ProcessMeta = (Process, DispatchWorkItem)
    typealias ProgressCallback = (String) -> Void
    typealias ProcessResult = ([String], [String], Int32)

    // intercept console output from the process or interrupt the process when problem occurred.
    func createBundleProcess(bundleName: String, bundleType: String? = nil,
                                   arguments: [String]?, progressCallback: ProgressCallback? = nil,
                                   callback: @escaping (ProcessResult) -> Void) -> ProcessMeta? {
        guard let launchPath = Bundle.main.path(forResource: bundleName, ofType: bundleType) else {
            return nil
        }
        let process = Process()
        
        var output : [String] = []
        var error : [String] = []
        
        let outpipe = Pipe()
        process.standardOutput = outpipe
        let errpipe = Pipe()
        process.standardError = errpipe
        let task = DispatchWorkItem {
            process.launchPath = launchPath
            process.arguments = arguments
            process.standardInput = FileHandle.nullDevice
            
            let errorHandler: (Data) -> Void = { data in
                if let str = String(data: data, encoding: .utf8) {
                    print(str)
                    if str.contains("Error while decoding stream") {
                        process.interrupt()
                    }
                }
            }
            
            var outdata = Data()
            outpipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                outdata.append(data)
                if let msg = String(data: data, encoding: .utf8) {
                    progressCallback?(msg)
                }
                errorHandler(data)
            }
            var errdata = Data()
            errpipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                errdata.append(data)
                if let msg = String(data: data, encoding: .utf8) {
                    progressCallback?(msg)
                }
                errorHandler(data)
            }
            
            process.terminationHandler = { process in
                if var string = String(data: outdata, encoding: .utf8) {
                    string = string.trimmingCharacters(in: .newlines)
                    output = string.components(separatedBy: "\n")
                }
                if var string = String(data: errdata, encoding: .utf8) {
                    string = string.trimmingCharacters(in: .newlines)
                    error = string.components(separatedBy: "\n")
                }
                callback((output, error, process.terminationStatus))
            }
            process.launch()
            process.waitUntilExit()
        }
        return (process, task)
    }
    
}

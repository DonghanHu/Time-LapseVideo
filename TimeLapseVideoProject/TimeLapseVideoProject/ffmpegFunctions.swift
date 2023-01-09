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
    
    // return a process and dispatchWorkItem, code this later
    // 
    func generateTimeLapseVideo(inputFilePath: String, outputFilePath: String,
                     callback: @escaping (Bool) -> Void) -> (Process, DispatchWorkItem)? {
        
        // set ffmpeg terminal code: launch path
        guard let launchPath = Bundle.main.path(forResource: "ffmpeg", ofType: "") else {
            return nil
        }
        
        let process = Process()
        // ffmpeg -r 24 -f image2 -pattern_type glob -i "*?png" -vcodec libx264 -crf 20 -pix_fmt yuv420p output.mp4
        let task = DispatchWorkItem {
            process.launchPath = launchPath
            process.arguments = [
                "-i", inputFilePath,
                "-r", "10", "-f", "image2", "-pattern_type", "glob",
                "-vcodec", "libx264", "-crf", "20", "-pix-fmt", "yuv420p",
                "timekapseVideo.mp4", outputFilePath
            ]
            // print(process.arguments)
            process.standardInput = FileHandle.nullDevice
            process.launch()
            process.terminationHandler = { process in
                callback(process.terminationStatus == 0)
            }
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: task)
        
        return (process, task)
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

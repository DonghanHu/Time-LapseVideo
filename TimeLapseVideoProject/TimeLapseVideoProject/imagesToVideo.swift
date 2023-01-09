//
//  imagesToVideo.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 12/7/22.
//  Copyright © 2022 Donghan Hu. All rights reserved.
//

import Foundation
import AVFoundation
import Photos
import AVKit
import AppKit


// class to transfer images to a video

struct RenderSettings {

    var size : CGSize = .zero
    var fps: Int32 = 6   // frames per second
    var avCodecKey = AVVideoCodecType.h264
    var videoFilename = "render"
    var videoFilenameExt = "mp4"

    var outputURL: URL {
        // Use the CachesDirectory so the rendered video file sticks around as long as we need it to.
        // Using the Download folder Directory ensures the file won't be included in a backup of the app.
        let fileManager = FileManager.default
        
        if let DownloadDirURL = try? fileManager.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return DownloadDirURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt)
        }
//        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
//            return tmpDirURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt)
//        }
        fatalError("URLForDirectory() failed")
    }
}
    
/*
The ImageAnimator class knows about your images and uses the VideoWriter class to perform the rendering. The idea is to keep the video content code separate from the low-level AVFoundation code. I also added saveToLibrary() here as a class function which gets called at the end of the chain to save the video to the Photo Library.
*/
class ImageAnimator {

    // Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
    static let kTimescale: Int32 = 600

    // default settings: file name, outputURL, etc
    let settings: RenderSettings
    
    let videoWriter: VideoWriter
    // an array of images for rendering video
    // code loadimages function to load these images
    var images: [NSImage]!

    var frameNum = 0

    // save the video to the Photo Library as default
    // from Download folder?
    class func saveToLibrary(videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if !success {
                    print("Could not save video to photo library:", Error.self)
                }
            }
        }
    }

    // delete the original generated video
    class func removeFileAtURL(fileURL: URL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
        }
        catch _ as NSError {
            // Assume file doesn't exist.
        }
    }

    // Initialization is the process of preparing an instance of a class, structure, or enumeration for use.
    init(renderSettings: RenderSettings) {
        settings = renderSettings
        videoWriter = VideoWriter(renderSettings: settings)
        // code here later
        //images = loadImages()
    }

    func render(completion: (()->Void)?) {

        // The VideoWriter will fail if a file exists at the URL, so clear it out first.
        ImageAnimator.removeFileAtURL(fileURL: settings.outputURL)

        videoWriter.start()
        videoWriter.render(appendPixelBuffers: appendPixelBuffers) {
            ImageAnimator.saveToLibrary(videoURL: self.settings.outputURL)
            completion?()
        }

    }

    // This is the callback function for VideoWriter.render()
    func appendPixelBuffers(writer: VideoWriter) -> Bool {

        let frameDuration = CMTimeMake(value: Int64(ImageAnimator.kTimescale / settings.fps), timescale: ImageAnimator.kTimescale)

        while !images.isEmpty {

            if writer.isReadyForData == false {
                // Inform writer we have more buffers to write.
                return false
            }

            let image = images.removeFirst()
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameNum))
            let success = videoWriter.addImage(image: image, withPresentationTime: presentationTime)
            if success == false {
                fatalError("addImage() failed")
            }

            frameNum += 1
        }

        // Inform writer all buffers have been written.
        return true
    }
}
    
class VideoWriter {

    let renderSettings: RenderSettings

    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!

    var isReadyForData: Bool {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }

    class func pixelBufferFromImage(image: NSImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {

        var pixelBufferOut: CVPixelBuffer?

        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }

        let pixelBuffer = pixelBufferOut!

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

        context!.clear(CGRect(x:0,y: 0,width: size.width,height: size.height))

        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        //aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit

        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)

        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0

        context?.draw(image.cgImage as! CGLayer, in: CGRect(x:x,y: y, width: newSize.width, height: newSize.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }

    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }

    func start() {

        let avOutputSettings: [String: Any] = [
            AVVideoCodecKey: renderSettings.avCodecKey,
            AVVideoWidthKey: NSNumber(value: Float(renderSettings.size.width)),
            AVVideoHeightKey: NSNumber(value: Float(renderSettings.size.height))
        ]

        func createPixelBufferAdaptor() {
            let sourcePixelBufferAttributesDictionary = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSettings.size.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSettings.size.height))
            ]
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                      sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        }

        func createAssetWriter(outputURL: URL) -> AVAssetWriter {
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4) else {
                fatalError("AVAssetWriter() failed")
            }

            guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaType.video) else {
                fatalError("canApplyOutputSettings() failed")
            }

            return assetWriter
        }

        videoWriter = createAssetWriter(outputURL: renderSettings.outputURL)
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)

        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        else {
            fatalError("canAddInput() returned false")
        }

        // The pixel buffer adaptor must be created before we start writing.
        createPixelBufferAdaptor()

        if videoWriter.startWriting() == false {
            fatalError("startWriting() failed")
        }

        videoWriter.startSession(atSourceTime: CMTime.zero)

        precondition(pixelBufferAdaptor.pixelBufferPool != nil, "nil pixelBufferPool")
    }

    func render(appendPixelBuffers: ((VideoWriter)->Bool)?, completion: (()->Void)?) {

        precondition(videoWriter != nil, "Call start() to initialze the writer")

        let queue = DispatchQueue(label: "mediaInputQueue")
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            let isFinished = appendPixelBuffers?(self) ?? false
            if isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting() {
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
            }
            else {
                // Fall through. The closure will be called again when the writer is ready.
            }
        }
    }
    

    func addImage(image: NSImage, withPresentationTime presentationTime: CMTime) -> Bool {

        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")

        let pixelBuffer = VideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
}
    
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

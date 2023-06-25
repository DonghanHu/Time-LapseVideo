//
//  AppDelegate.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 9/13/22.
//  Copyright © 2022 Donghan Hu. All rights reserved.
//

import Cocoa
import AppKit
import UserNotifications


struct Repository {
    // folder to save screenshots based on date
    static var defaultFolderPathString              =   ""
    static var defaultFolderPathURL                 =   URL(string: "default_folder_path")
    
    // folder to save generated time-lapse videos
    static var downloadingVideosFolderPathString    =   "default video downloading folder path"
    static var downloadingVideosFolderPathURL       =   URL(string: "default_downloading_folder_path")
    
    static var dailyScreenshotFolderString          =   ""
    static var dailyScreenshotFolderURL             =   URL(string: "daily_folder_path")
    
}

struct Setting {
    static var frameRate : Int                      =   12
    static var captureInterval : Int                =   10
}

struct DailyCounter {
    // null value
    static var dateStr                              =   ""
    // initialize counter as 0 as the first one
    static var counter                              =   0
}

struct DailyNotification {
    // null value
    static var dateStr                              =   ""
    static var wathchedTimeLapseVideo               =   false
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate{


    // private var window: NSWindow!
    
    private var statusItem: NSStatusItem!
    
    private var startButton: NSMenuItem!
    private var watchButton: NSMenuItem!
    private var saveFolderButton: NSMenuItem!
    
    private var settingButton: NSMenuItem!
    
    private var recordingFlag: Bool!
    
    private var timeInterval = 10.0
    
    private var takingScreenshotsTimer = Timer()
    
    private var timerMonitorThread = Thread()
    
    private var setVideoDownloadingPathWindowController: setVideoPath?
    private var setParametersController: videoWatchWindow?
    
    // notification center
    let un = UNUserNotificationCenter.current()
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // button.title = "T"
            // quickLookTemplateName
            button.image = NSImage(named: "videoIcon");
//            button.image = NSImage(pasteboardPropertyList: "1.circle", ofType: NSPasteboard.PasteboardType(rawValue: "1"))
            
        }
        // obtain and set default folder to save screenshots
        let defaultFolderPathString = getHomePath() + "/Documents/" + "TimeLapseVideo/Screenshots/"
        Repository.defaultFolderPathString = defaultFolderPathString
        Repository.defaultFolderPathURL = URL(string: defaultFolderPathString)
        
        // create a default folder for saving screenshots
        checkDefaultFolder(folderPath: defaultFolderPathString)
        
        let savingVideoFolderPathString = getHomePath() + "/Documents/" + "TimeLapseVideo/Videos/"
        checkDefaultFolder(folderPath: savingVideoFolderPathString)
        
        // take a testing screenshot while launching the application for asking request
         takeTestingImage()
         deleteTestingImage()
        
        // set up initial values for date and use it to compare with other dates' string
        let currentDateString = getCurrentDate()
        DailyCounter.dateStr = currentDateString
        DailyNotification.dateStr = currentDateString
        
        // set up the menu on menu bar
        setupMenus()
        
        // set the recorind flag
        recordingFlag = false
        
        // get all folders from the target root path
        folderList()
        
        // request for sending local notification
        // requestNotification()
        // request for permission to send notification
        un.requestAuthorization(options: [.alert, .sound]) { (authorized, error) in
            if authorized {
                print("Authorized")
            } else if !authorized {
                print("Not authorized")
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        sleep(1)
        // set notification for only one time
        
        let hasLaunchedKey = "HasLaunched"
        let defaults = UserDefaults.standard
        let hasLaunched = defaults.bool(forKey: hasLaunchedKey)
        print("haslaunched 1 " + String(hasLaunched))
        var authorizedFlag = false
        un.getNotificationSettings { (settings) in
            // print(type(of: settings.authorizationStatus))
            if settings.authorizationStatus == .authorized {
                print("status is authorized")
                authorizedFlag = true
            }
        }
        sleep(1)
        print(authorizedFlag)
        if !hasLaunched && authorizedFlag{
            print("both true")
            defaults.set(true, forKey: hasLaunchedKey)
            // set notification()
            setWeekdayNotification()
        } else{
            // reset default values
            let appDomain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
        sleep(1)
        
        // set default folder to save created time-lapse videos： Downloads folder
        // let defaultDownloadingVideosFolderPath = getHomePath() + "/Downloads/"
        // changed to "Documents/timelapsevideo"
        let defaultDownloadingVideosFolderPath = getHomePath() + "/Documents/TimeLapseVideo/Videos/"
        Repository.downloadingVideosFolderPathString = defaultDownloadingVideosFolderPath
        Repository.downloadingVideosFolderPathURL = URL(string: defaultDownloadingVideosFolderPath)
        
        if(FileManager.default.fileExists(atPath: defaultDownloadingVideosFolderPath)){
            print("default folder for saving videos is already existed!")
        }
        else{
            print("default folder for saving videos does not exist")
            // do...
        }
        
        timerMonitorThread = Thread(target: self, selector: #selector(timerValidationChecking), object: nil)
        timerMonitorThread.start()

    }
    
    @objc func timerValidationChecking() {
        while(timerMonitorThread.isExecuting == true){
            if (takingScreenshotsTimer.isValid){
                // print("timer is running")
                startButton.title = "Stop Recording"
                DispatchQueue.main.sync {
                    self.statusItem.button?.image = NSImage(named: "recordIcon");
                }
                
            } else {
                // print("timer is stopped")
                startButton.title = "Start Recording"
                DispatchQueue.main.sync {
                    self.statusItem.button?.image = NSImage(named: "videoIcon");
                }
                
            }
        }
    }
    
    @objc func getPendingNotifications() async {
        var pendings = await un.pendingNotificationRequests()
        print("pendings: \(pendings.count)")
        print(pendings)
    }
    
    //
    @objc func requestNotification(){
        un.requestAuthorization(options: [.sound, .alert]) {(authorized, error) in
            if authorized {
                print("notification is authorized")
            } else if !authorized{
                print("notification is not authorized")
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
    }
    
    // function to creat the menu bar app's menu
    func setupMenus() {

        let menu = NSMenu()

        startButton = NSMenuItem(title: "Start Recording", action: #selector(didTapOne) , keyEquivalent: "1")
        menu.addItem(startButton)

//        watchButton = NSMenuItem(title: "Generate Today Video", action: #selector(didTapTwo) , keyEquivalent: "2")
//        menu.addItem(watchButton)
        
        // remove
//        saveFolderButton = NSMenuItem(title: "Video Path", action: #selector(didTapThree) , keyEquivalent: "3")
//        menu.addItem(saveFolderButton)
        
//        let yesterdayVideoButton = NSMenuItem(title: "oops! Yesterday!", action: #selector(generateYesterDayVideo), keyEquivalent: "3")
//        menu.addItem(yesterdayVideoButton)
        
        
        let generateAllVideos = NSMenuItem(title: "Generate All Videos", action: #selector(generateAllVideosFunc), keyEquivalent: "2")
        menu.addItem(generateAllVideos)
        
        let openFolderButton = NSMenuItem(title: "Open Folder", action: #selector(openVideoFolder), keyEquivalent: "3")
        menu.addItem(openFolderButton)
        
        settingButton = NSMenuItem(title: "Setting", action: #selector(settingWindow) , keyEquivalent: "4")
        menu.addItem(settingButton)
        

        
        // remove
//        let testButton = NSMenuItem(title: "test button", action: #selector(getPendingNotifications) , keyEquivalent: "4")
//        menu.addItem(testButton)
        
        // button for testing notifiaction setting
//        let notificationButton = NSMenuItem(title: "notification", action: #selector(didTapFive), keyEquivalent: "5")
        // menu.addItem(notificationButton)
        
        // add a line separator
        menu.addItem(NSMenuItem.separator())

        // menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func quitApplication(){
        timerMonitorThread.cancel()
        print("thread is cancelled or not: ", timerMonitorThread.isCancelled)
        exit(0)
    }
    
    // function for opening the setting window
    @objc func settingWindow(){
        
        setParametersController = videoWatchWindow()
        setParametersController?.showWindow(self)
        setParametersController?.window?.level = .mainMenu + 1
        
    }
    
    
    @objc func generateAllVideosFunc() {
        // step 1: get the list of folders
        // step 2: for each folder, create a video name and check if it is already existed in the video folder
        // step 3: create video for corresponding screenshot folders
        // step 4: corner cases: today and yesterday, no matter what, generate two videos for covering all screenshots
        
        var screenshotFolderNameList = [String]()
        var screenshotFolderNameListCount = 0
        let ffmpegHandler = ffmpegClass()
        var screenshotFolder = getHomePath() + "/Documents/TimeLapseVideo/Screenshots/"
        // /Documents/TimeLapseVideo/Videos/
        let defaultOutputPath = Repository.downloadingVideosFolderPathString
        
        
        let fileManager = FileManager.default
        var error : NSError?
        do{
            let folderArray = try? FileManager.default.contentsOfDirectory(atPath: screenshotFolder) as [String]
            let numberOfFolders = folderArray?.count
            // should exclude ".DS_Store"
            screenshotFolderNameList = folderArray!
        }catch{
            print("error: \(error)")
        }
        
        // remove ".DS_Store" from screenshot folder
        if let index = screenshotFolderNameList.firstIndex(of: ".DS_Store") {
            screenshotFolderNameList.remove(at: index)
        }
        print("the name list of screenshot folder: ", screenshotFolderNameList)
        
        // get existed time-lapse video names
        var videosNameList = [String]()
        let videosNameListCount = 0
        do {
            let folderArray = try? FileManager.default.contentsOfDirectory(atPath: defaultOutputPath) as [String]
            videosNameList = folderArray!
        } catch {
            print("error: \(error)")
        }
        // remove ".DS_Store" from video folder
        // remove ".DS_Store"
        if let index = videosNameList.firstIndex(of: ".DS_Store") {
            videosNameList.remove(at: index)
        }
        print("the name list of video folder: ", videosNameList)
        screenshotFolderNameListCount = screenshotFolderNameList.count
        
        for scrFolderName in screenshotFolderNameList {
            let tempFolderNameInputFilePath = Repository.defaultFolderPathString + scrFolderName
            print("this is single screenshot folder name: ", tempFolderNameInputFilePath)
            // input is tempFolderName
            var desiredVideoFileName = transferScreenshotFolderToVideoFolder(folderName: scrFolderName)
            print("desired corresponding time-lapse video name is:", desiredVideoFileName)
            
            
            print("tempFolderNameInputFilePath is: ", tempFolderNameInputFilePath)
            print("defaultOutputPaht is: ", defaultOutputPath)
            
            
            if(videosNameList.contains(desiredVideoFileName)){
                // this video is existed
                
                var isToday = checkToday(str: scrFolderName)
                
                // condition 1: today's video, create a new one and overwrite the previous one
                if(isToday) {
                    print("vidoe existed and isToday")
                    ffmpegHandler.createAndOverwriteTimeLapseVideo(inputFilePath: tempFolderNameInputFilePath, outputFilePath: defaultOutputPath)
                    // do not revome this screenshot folder
                }
                // condition 2: yesterday or last time generating a video
                else {
                    print("vidoe existed and is not Today")
                    // this is yesterday's screenshot folder, in case captured additional screenshots after geneateing a video from last time
                    // create and overwite, remove this old screenshot folder
                    ffmpegHandler.createAndOverwriteTimeLapseVideoForPastDate(scrFolderName: scrFolderName, inputFilePath: tempFolderNameInputFilePath, outputFilePath: defaultOutputPath)
                    // ffmpegHandler.createAndOverwriteTimeLapseVideo(inputFilePath: tempFolderNameInputFilePath, outputFilePath: defaultOutputPath)
                    do {
                        let fileManager = FileManager.default
                        // Check if file exists
                        let scrFolderNameURL = URL(string: tempFolderNameInputFilePath)
                        if fileManager.fileExists(atPath: tempFolderNameInputFilePath) {
                            print("folder existed")
                            // Delete file, comment this line for now
                            try fileManager.removeItem(atPath: tempFolderNameInputFilePath)
                        } else {
                            print("File does not exist")
                        }
                    } catch { print("An error took place: \(error)")}
                    
                }
                
                // Use the -y option to automatically overwrite
                // ffmpeg -y -i input.flac output.mp3
                
                // create a new video and replace old ones
                //                print("this is inputfilepath: ", tempFolderNameInputFilePath)
                //                print("this is outputfilepath: ", defaultOutputPath)
            } else {
                // doesnt have this video with corresponding screenshot folder,
                
                // if is today, create a new one
                var isToday = checkToday(str: scrFolderName)
                if(isToday) {
                    //
                    print("vidoe does not existed and isToday")
                    ffmpegHandler.createAndOverwriteTimeLapseVideo(inputFilePath: tempFolderNameInputFilePath, outputFilePath: defaultOutputPath)
                }
                else {
                    print("vidoe does not existed and is not Today")
                    // this is not today's screenshot folder, forgot to create videos in the past few days
                    // step 1: create videos for this screenshot folder
                    ffmpegHandler.createAndOverwriteTimeLapseVideoForPastDate(scrFolderName: scrFolderName, inputFilePath: tempFolderNameInputFilePath, outputFilePath: defaultOutputPath)
                    // ffmpegHandler.createAndOverwriteTimeLapseVideo(inputFilePath: tempFolderNameInputFilePath, outputFilePath: defaultOutputPath)
                    // step 2: remove this folder, because there is no more new screenshots for past days
                    do {
                        let fileManager = FileManager.default
                        // Check if file exists
                        let scrFolderNameURL = URL(string: tempFolderNameInputFilePath)
                        if fileManager.fileExists(atPath: tempFolderNameInputFilePath) {
                            print("folder existed")
                            // Delete file, comment this line for now
                            try fileManager.removeItem(atPath: tempFolderNameInputFilePath)
                        } else {
                            print("File does not exist")
                        }
                    } catch { print("An error took place: \(error)")}
                    //                print("this is inputfilepath: ", tempFolderNameInputFilePath)
                    //                print("this is outputfilepath: ", defaultOutputPath)
                }
            }
        }
        
    }
    
    // check the date if is today
    func checkToday(str : String) -> Bool {
        // str is screenshot folder name
        let components = str.components(separatedBy: "-")
        var month = components[0]
        var day = components[1]
        var year = components[2]
        
        let date = Date()
        let calendar = NSCalendar.current
        let CalendarDay = calendar.component(.day, from: date)
        let CalendarMonth = calendar.component(.month, from: date)
        let CalendarYear = calendar.component(.year, from: date)
        
        let dayString = String(CalendarDay)
        let monthString = String(CalendarMonth)
        let yearString = String(CalendarYear)
        
        return day == dayString && month == monthString && year == yearString
        
    }
    // check the date if is yesterday
    func checkYesterday(str: String) -> Bool {
        // str is screenshot folder name
        let components = str.components(separatedBy: "-")
        var month = components[0]
        var day = components[1]
        var year = components[2]
        
        let yesterdayDay = String(Date.yesterday.returnDay)
        let yesterdayMonth = String(Date.yesterday.returnMonth)
        let yesterdayYear = String(Date.yesterday.returnYear)
        let yesterday = Date.yesterday
        
        print(yesterday)
        print("yesterday is: ", day, month, year)
        print(type(of: yesterday)) // Date
        let yesterdayDate = Calendar.current.dateComponents([.day], from: yesterday)
        print(type(of: yesterdayDate)) // DateComponents
        print(type(of: yesterdayDate.day))
        let yesterdayInt = (yesterdayDate.day!) as Int
        let yesterdayDateInString = "\(yesterdayDate.day)"
        print(yesterdayInt)
        let yesterdayStr = String(yesterdayInt)
        print(String(yesterdayInt))
        print(yesterdayDateInString)
        
        return day == yesterdayStr && month == yesterdayMonth && year == yesterdayYear
        
    }
    
    func transferScreenshotFolderToVideoFolder(folderName: String) -> String{
        let components = folderName.components(separatedBy: "-")
        var month = components[0]
        var day = components[1]
        var year = components[2]
        if (month.count < 2){
            month = "0" + month
        }
        if(day.count < 2){
            day = "0" + day
        }
        // + ".mp4"?
        return "TimeLapseVideo" + month + day + year + ".mp4"
        // return month + "-" + day + "-" + year
        
    }
    
    // function to create all videos that are missing
    // code here
    @objc func createAllVideos(){
        var videoFolder = getHomePath() + "/Documents/TimeLapseVideo/Videos/"
        var sceenshotFolderNumber: Int = 0
        var timelapseVideoNumber: Int = 0
        var timelapseVideoNameArray: [String] = []
        var screenshotsFolderNameArray: [String] = []
        let fileManager = FileManager.default
        var error : NSError?
        
        let date = Date()
        let calendar = NSCalendar.current
        let CurrentYear = calendar.component(.year, from: date)
        
        do{
            let videoNameArray = try? FileManager.default.contentsOfDirectory(atPath: videoFolder) as [String]
            timelapseVideoNameArray = videoNameArray ?? []
            let numberOfItems = try FileManager.default.contentsOfDirectory(atPath: videoFolder).count
            timelapseVideoNumber = numberOfItems
        }catch{
            print("error: \(error)")
        }
        
        var screenshotDailyFolder = getHomePath() + "/Documents/TimeLapseVideo/Screenshots/"
        if fileManager.fileExists(atPath: screenshotDailyFolder){
            print("screenshot folder is existed")
            do {
                let screenshotsFolderArray = try? FileManager.default.contentsOfDirectory(atPath: screenshotDailyFolder) as [String]
                screenshotsFolderNameArray = screenshotsFolderArray ?? []
                let numberOfFolders = try FileManager.default.contentsOfDirectory(atPath: screenshotDailyFolder).count
                sceenshotFolderNumber = numberOfFolders
            } catch{
                print("error: \(error)")
            }
        } else{
            print("screenshot folder is not existed under document/timelapsevideo directory")
        }
        
        // output "MM.dd,HH-mm-ss" output03.01,23-45-26.mp4
        // 4-11-2023
        let tA = timelapseVideoNameArray
        // screenshots folder should always greater or equal to timelapse videos
        for i in tA {
            print(i)
            if(i == ".DS_Store"){
                continue
            } else{
                let start = i.index(i.startIndex, offsetBy: 6)
                let end = i.index(i.endIndex, offsetBy: -16)
                let range = start..<end
                let monthSection = i[range]
                let start1 = i.index(i.startIndex, offsetBy: 9)
                let end1 = i.index(i.endIndex, offsetBy: -13)
                let range1 = start..<end
                let daySection = i[range1]
                let month = removeZero(str: String(monthSection))
                let day = removeZero(str: String(daySection))
                let newFolderName = month + "-" + day + "-" + String(CurrentYear)
                print(newFolderName)
                
            }
        }
        
        
    }
    // funciton remove 0 at the begining of month and day
    func removeZero(str: String) -> String{
        let characters = Array(str)
        if characters[0] == "0"{
            let res = characters[1]
            return String(res)
        } else{
            return str
        }
    }
    
    // function to open video folder
    @objc func openVideoFolder(){
        let documentFolderPath = getHomePath() + "/Documents/TimeLapseVideo"
        if(FileManager.default.fileExists(atPath: documentFolderPath)){
            print("Target folder is already existed!")
            NSWorkspace.shared.open(
                URL(
                    fileURLWithPath: documentFolderPath,
                    isDirectory: true
                )
            )
        }
        else{
            print("/Documents/TimeLapseVideo/ not existed")
            
        }

    }
    
    // function to set notification on weekdays
    func setWeekdayNotification() {
        
        // cancel all other notifications
        self.un.removeAllPendingNotificationRequests()
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        print("set notifications for five weekdays")
        un.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                
                // weekdays: 1 is Sunday
                let weekdays = [2, 3, 4, 5, 6]
                
                for day in weekdays {
                    
                    let weekday = Int(day)
                    print("this is day: ", weekday)
                    var components = DateComponents()
                    components.hour = 17
                    components.minute = 0
                    components.second = 0
                    components.weekday = weekday
                    // not sure how this works, but this is essential to reset weekday in triggerweekly
                    // components.weekdayOrdinal = 1
                    components.weekdayOrdinal = 6
                    components.timeZone = .current
                    let calendar = Calendar(identifier: .gregorian)
                    let calenderDate = calendar.date(from: components)!
                    var triggerWeekly = Calendar.current.dateComponents([.weekday,.hour,.minute,.second], from: calenderDate)
                    triggerWeekly.isLeapMonth = false
//                    print(type(of: weekday))
                    print("this is triggerWeekly")
                    print(triggerWeekly)
                    print("this is weekday")
                    print(triggerWeekly.weekday)
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerWeekly, repeats: true)

                    let content = UNMutableNotificationContent()
                    content.title = "Time-lapse video reminder."
                    content.body = "Please remember to review your today's time-lapse video. Thank you!"
                    content.sound = UNNotificationSound.default
                    content.categoryIdentifier = "timelapsevideo"

                    let request = UNNotificationRequest(identifier: "textNotification", content: content, trigger: trigger)
                    self.un.delegate = self
                    self.un.add(request) { (error) in
                        if error != nil {
                            print(error?.localizedDescription as Any)
                        }
                    }

                }
                // time interval should be at least 60 if repeated
                // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
            }
            
        }
    }
    
    @objc func didTapFive() {
        
        // cancel all other notifications
        self.un.removeAllPendingNotificationRequests()
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        print("set notifications for five weekdays")
        un.getNotificationSettings { (settings) in
            if settings.authorizationStatus == .authorized {
                
//                let filePath = Bundle.main.path(forResource: "notificationIcon", ofType: ".png")
//                let fileUrl = URL(fileURLWithPath: filePath!)
//                do {
//                    let attachment = try UNNotificationAttachment.init(identifier: "AnotherTest", url: fileUrl, options: .none)
//                    content.attachments = [attachment]
//
//                } catch let error {
//                    print(error.localizedDescription as Any)
//                }
                
                // weekdays: 1 is Sunday
                let weekdays = [2, 3, 4, 5, 6]
                // uuid as identifier
                let testUUIDString = UUID().uuidString;
                
                for day in weekdays {
                    let weekday = Int(day)
                    var components = DateComponents()
                    components.hour = 17
                    components.minute = 0
                    components.second = 0
                    // not sure how this works, but this is essential to reset weekday in triggerweekly
                    components.weekdayOrdinal = 10
                    components.weekday = weekday
                    components.timeZone = .current
                    let calendar = Calendar(identifier: .gregorian)
                    let calenderDate = calendar.date(from: components)!
                    
                    var triggerWeekly = Calendar.current.dateComponents([.weekday,.hour,.minute,.second,], from: calenderDate)
                    // what is leapmonth
                    triggerWeekly.isLeapMonth = false
                    print(type(of: weekday))
                    print(triggerWeekly)
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerWeekly, repeats: true)

                    let content = UNMutableNotificationContent()
                    content.title = "Time-lapse vidoe reminder."
                    content.body = "Please remember to review your today's time-lapse video. Thank you!"
                    content.sound = UNNotificationSound.default
                    content.categoryIdentifier = "timelapsevideo"

                    let request = UNNotificationRequest(identifier: "textNotification", content: content, trigger: trigger)
                    
                    self.un.add(request) { (error) in
                        if error != nil {
                            print(error?.localizedDescription as Any)
                        }
                    }

                }
                // time interval should be at least 60 if repeated
                // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
            }
            
        }
    }
    
    
    // test button for generating time lapse video
    @objc func didTapfour(){
        // let inputStringPath = "Users/donghanhu/Desktop/ScreenshotsForVideos/*?jpg"
        // let outputStringPath = "Users/donghanhu/Downloads/output.mp4"
        let inputStringPath = "\"file://Users/donghanhu/Desktop/ScreenshotsForVideos/Frame00000151jpg\""
        let outputStringPath = "\"/Users/donghanhu/Downloads/output.mp4\""
        let ffmpegHandler = ffmpegClass()
        print("input file path is: " + inputStringPath)
        print("output file path is: " + outputStringPath)
        // ffmpegHandler.generateTimeLapseVideo(inputFilePath: inputStringPath, outputFilePath: outputStringPath)
        ffmpegHandler.basicFunction(inputFilePath: inputStringPath, outputFilePath: outputStringPath)
    }
    
    // first button action
    @objc func didTapOne() {
        
        // compare default date string with current date and reset default values
        let currentDateString = getCurrentDate()
        // if two strings are not equal, reset default values
        if DailyCounter.dateStr != currentDateString {
            DailyCounter.dateStr = currentDateString
            DailyCounter.counter = 0
            DailyNotification.dateStr = currentDateString
            DailyNotification.wathchedTimeLapseVideo = false
        }
        
        // set button attributes
        let startButtonTitle = startButton.title
        if (startButtonTitle == "Start Recording"){
            startButton.title = "Stop Recording"
            
            self.statusItem.button?.image = NSImage(named: "recordIcon");
            // set the recording flag to true
            recordingFlag = true
            let takeScreenshotsObject = takeScreenshots()
            takeScreenshotsObject.creatFolderForTodayRecording()
            
            takeScreenshotsObject.takeANewScreenshotWithFormattedDateName()
            

            // not taking a ascreenshot at the time when click this button
            self.takingScreenshotsTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(Setting.captureInterval), repeats: true, block: { _ in
                takeScreenshotsObject.takeANewScreenshotWithFormattedDateName()
            })
//            self.takingScreenshotsTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { _ in
//                takeScreenshotsObject.takeANewScreenshotWithFormattedDateName()
//            })
            
        }else {
            startButton.title = "Start Recording"
            // set the recording flag to false
            self.statusItem.button?.image = NSImage(named: "videoIcon");
            recordingFlag = false
            
            // stop the timer
            self.takingScreenshotsTimer.invalidate()
        }
        
        print("tapped record button.")
        
    }

    // function to create time-lapse video
    @objc func didTapTwo() {
        print("tapped generate video button.")

        // use current saving path to save created video
        // e.g., user/Downloads/
        print("current folder for saving time-lapse videos is: " + Repository.downloadingVideosFolderPathString)
        
        // get today's screenshots' folder
        let takeScreenshotsHandler = takeScreenshots()
        let tempfolderPath = takeScreenshotsHandler.returnCurrentFolder()
        print("screenshots folder is: " + tempfolderPath)
        
        if(FileManager.default.fileExists(atPath: tempfolderPath)){
            print("today's screenshot folder is already existed!")
            print("today folder is: " + tempfolderPath)
            // create time-lapse videos
            let ffmpegHandler = ffmpegClass()
            let outputPath = Repository.downloadingVideosFolderPathString
            ffmpegHandler.basicFunction(inputFilePath: tempfolderPath, outputFilePath: outputPath)
            
        }
        else{
            print("Today, you haven't taken any screenshots yet!")
            // do...
            let alert = NSAlert()
            alert.messageText = "Today, you haven't taken any screenshots yet!"
            alert.informativeText = "Please remember to record your today activities. "
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
 
    }
    
    // MARK: generate time-lapse video for yesterday screeenshots
    @objc func generateYesterDayVideo(){
        print("generate yesterday video here")
        var YesterdayFolderPath : String = ""
        let yesterdayDay = String(Date.yesterday.returnDay)
        let yesterdayMonth = String(Date.yesterday.returnMonth)
        let yesterdayYear = String(Date.yesterday.returnYear)
        let yesterdayFolderName = yesterdayMonth + "-" + yesterdayDay + "-" + yesterdayYear
        
        YesterdayFolderPath = getHomePath() + "/Documents/TimeLapseVideo/Screenshots/" + yesterdayFolderName
        
        if(FileManager.default.fileExists(atPath: YesterdayFolderPath)){
            print("Yesterdday's screenshot folder is already existed!")
            // create time-lapse videos
            let ffmpegHandler = ffmpegClass()
            let outputPath = Repository.downloadingVideosFolderPathString
            ffmpegHandler.basicFunction(inputFilePath: YesterdayFolderPath, outputFilePath: outputPath)

        }
        else{
            print("Yesterday, you didn't take any screenshots!")
            // do...
            let alert = NSAlert()
            alert.messageText = "Yesterday, you didn't take any screenshots!"
            alert.informativeText = "Please remember to record your today activities. "
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    // get a list of all folders
    func folderList(){
    
        let rootPath = getHomePath() + "/Documents/" + "TimeLapseVideo/Screenshots/"
//        let folderList = NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: rootPath)
//        print("folderList: ")
//        print(folderList)
        
        let rootPathURL = URL(string: rootPath)
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: rootPath)

            for item in items {
                // corner case
                if(item == ".DS_Store"){
                    continue
                }
                // let time = item[FileAttributeKey.creationDate]
                let folderPath = rootPath + item + "/"
                print(folderPath)
                do {
                    let folder = try FileManager.default.attributesOfItem(atPath: folderPath) as [FileAttributeKey:Any]
                    let creationDate = folder[FileAttributeKey.creationDate] as! Date
                    print("Found \(creationDate)")
                    
                    let currentDate = Date()
                    // print(currentDate)
                    
                    // one week for saving (7 days for now)
                    let pastTime = creationDate.addingTimeInterval(604800)
                    //if true, should be deleted
                    // print(currentDate > pastTime)
                    // delete
                    if(currentDate > pastTime){
                        do {
                            let fileManager = FileManager.default
                            // Check if file exists
                            if fileManager.fileExists(atPath: folderPath) {
                                print("folder existed")
                                // Delete file, comment this line for now
                                try fileManager.removeItem(atPath: folderPath)
                            } else {
                                print("File does not exist")
                            }
                        } catch {
                            print("An error took place: \(error)")
                        }
                    } else{
                        // do nothing
                    }
                    
                    
                } catch let theError as Error {
                    print("file not found \(theError)")
                }
                
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
    }
    
    // action for the third button
    // currently, set the default folder as "Download"
    @objc func didTapThree() {
        print("tapped save folder path.")
        setVideoDownloadingPathWindowController = setVideoPath()
        setVideoDownloadingPathWindowController?.showWindow(self)
        setVideoDownloadingPathWindowController?.window?.level = .mainMenu + 1

    }
    
    // function to get current date string as a reference
    func getCurrentDate() -> String{

        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"
        let dateString = dateFormatter.string(from: date)
        return dateString
        
    }
    
    // function to return the computer's home path
    func getHomePath() -> String{
        let pw = getpwuid(getuid())
        let home = pw?.pointee.pw_dir
        let homePath = FileManager.default.string(withFileSystemRepresentation: home!, length: Int(strlen(home!)))
        return homePath
    }
    
    // function to creat default folder for saving screenshots
    func checkDefaultFolder(folderPath : String) {
        if FileManager.default.fileExists(atPath: folderPath){
            print("default is already existed!")
        }
        else {
            do {
                try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
                print(folderPath)
                print("default folder created successfully!")
            } catch {
                print("default folder created failed!")
                print(error)
            }
        }

    }
    
    // function to take a test screenshot for asking premission
    func takeTestingImage(){
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        var arguments = [String]();
        arguments.append("-x")

        arguments.append(Repository.defaultFolderPathString + "Testing.jpg")
        task.arguments = arguments

        let outpipe = Pipe()
        task.standardOutput = outpipe
        task.standardError = outpipe
         do {
           try task.run()
         } catch {}
        
        task.waitUntilExit()
        print("taking a test image is finished")
    }
    
    // funcitno to delete the test screenshot
    func deleteTestingImage(){
        let path = Repository.defaultFolderPathString  + "Testing.jpg"
        do {
          try FileManager.default.removeItem(atPath: path)
        } catch{
            print("error iin delete the testing image: \(error)")
        }
        
    }

    // function to quit the menu bar application
    func applicationWillTerminate(_ aNotification: Notification) {
        timerMonitorThread.cancel()
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "TimeLapseVideoProject")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(macOS 11.0, *) {
            return completionHandler([.list, .sound])
        } else {
            // Fallback on earlier versions
        }
        // return completionHandler([.list, .sound])
    }
}

extension Date {
    static var yesterday: Date{return Date().dayBefore}
    
    var dayBefore: Date{
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var noon: Date{
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
    
    var returnDay: Int{
        return Calendar.current.component(.day, from: self)
    }
    var returnMonth: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    var returnYear: Int {
        return Calendar.current.component(.year, from: self)
    }
    
}

//
//  AppDelegate.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 9/13/22.
//  Copyright © 2022 Donghan Hu. All rights reserved.
//

import Cocoa


struct Repository {
    static var defaultFolderPathString              =   ""
    static var defaultFolderPathURL                 =   URL(string: "default_folder_path")
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    // private var window: NSWindow!
    
    private var statusItem: NSStatusItem!
    
    private var startButton: NSMenuItem!
    private var watchButton: NSMenuItem!
    
    private var recordingFlag: Bool!
    
    private var timeInterval = 10.0
    
    private var takingScreenshotsTimer = Timer()
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        window = NSWindow(
//            contentRect: NSRect(x: 0, y: 0, width: 480, height: 270),
//            styleMask: [.miniaturizable, .closable, .resizable, .titled],
//            backing: .buffered, defer: false)
//        window.center()
//        window.title = "No Storyboard Window"
//        window.makeKeyAndOrderFront(nil)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // button.title = "T"
            
            button.image = NSImage(named: NSImage.quickLookTemplateName);
//            button.image = NSImage(pasteboardPropertyList: "1.circle", ofType: NSPasteboard.PasteboardType(rawValue: "1"))
            
        }
        // obtain and set default folder to save screenshots
        let defaultFolderPathString = getHomePath() + "/Documents/" + "TimeLapseVideo/Screenshots/"
        Repository.defaultFolderPathString = defaultFolderPathString
        Repository.defaultFolderPathURL = URL(string: defaultFolderPathString)
        
        
        // create a default folder for saving screenshots
        checkDefaultFolder(folderPath: defaultFolderPathString)
        
        // take a testing screenshot while launching the application for asking request
        // takeTestingImage()
        // deleteTestingImage()
        
        // set up the menu on menu bar
        setupMenus()
        
        // set the recorind flag
        recordingFlag = false
    
    }
    
    // function to creat the menu bar app's menu
    func setupMenus() {

        let menu = NSMenu()

        startButton = NSMenuItem(title: "Start Recording", action: #selector(didTapOne) , keyEquivalent: "1")
        menu.addItem(startButton)

        watchButton = NSMenuItem(title: "Watch Time-Lapse Video", action: #selector(didTapTwo) , keyEquivalent: "2")
        menu.addItem(watchButton)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }
    
    @objc func didTapOne() {
        
        let startButtonTitle = startButton.title
        if (startButtonTitle == "Start Recording"){
            startButton.title = "Stop Recording"
            
            // set the recording flag to true
            recordingFlag = true
            let takeScreenshotsObject = takeScreenshots()
            takeScreenshotsObject.creatFolderForTodayRecording()
            
            takeScreenshotsObject.takeANewScreenshot()
            
            // not taking a ascreenshot at the time when click this button
            self.takingScreenshotsTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { _ in
                takeScreenshotsObject.takeANewScreenshot()
            })
            
        }else {
            startButton.title = "Start Recording"
            // set the recording flag to false
            recordingFlag = false
            
            // stop the timer
            self.takingScreenshotsTimer.invalidate()
        }
        
        print("tapped record button.")
        
    }

    @objc func didTapTwo() {
        print("tapped watch button.")
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


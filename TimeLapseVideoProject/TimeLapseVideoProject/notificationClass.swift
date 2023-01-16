//
//  notificationClass.swift
//  TimeLapseVideoProject
//
//  Created by Donghan Hu on 1/15/23.
//  Copyright © 2023 Donghan Hu. All rights reserved.
//

import Foundation
import AppKit

class notificationCenter : NSObject, NSUserNotificationCenterDelegate {
    // method 1: with static information
    func showNotification() {
        
        
        // print("show notification method")
        
        let notification = NSUserNotification()
        
        // All these values are optional
        notification.title = "Test of notification"
        notification.subtitle = "Subtitle of notifications"
        notification.informativeText = "Main informative text"
        // notification.contentImage = contentImage
        notification.soundName = NSUserNotificationDefaultSoundName
        
//        sleep(5)
//        print("show notification method")
//        NSUserNotificationCenter.default.deliver(notification)
        
        notification.deliveryDate = Date(timeIntervalSinceNow: 5)
        NSUserNotificationCenter.default.scheduleNotification(notification)
        
    }
    
}

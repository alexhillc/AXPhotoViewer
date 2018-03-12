//
//  AppDelegate.swift
//  AXPhotoViewerExample
//
//  Created by Alex Hill on 5/7/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let cacheSizeMemory = 1024 * 1024 * 200
        let cacheSizeDisk = 1024 * 1024 * 200
        let sharedCache = URLCache(memoryCapacity: cacheSizeMemory, diskCapacity: cacheSizeDisk, diskPath: nil)
        URLCache.shared = sharedCache

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = TableViewController()
        self.window?.makeKeyAndVisible()
        
        return true
    }

}


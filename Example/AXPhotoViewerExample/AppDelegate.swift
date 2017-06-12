//
//  AppDelegate.swift
//  AXPhotoViewerExample
//
//  Created by Alex Hill on 5/7/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit
import SDWebImage

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        SDImageCache.shared().config.maxCacheAge = 60 * 60 * 24 * 2
        SDImageCache.shared().config.maxCacheSize = 1024 * 1024 * 40

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = ViewController()
        self.window?.makeKeyAndVisible()
        
        return true
    }

}


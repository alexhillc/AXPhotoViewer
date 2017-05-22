//
//  AppDelegate.swift
//  BAPPhotosViewControllerExample
//
//  Created by Alex Hill on 5/7/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit
import BAPPhotosViewController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PhotosViewControllerDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let photos = [
            ExamplePhoto(title: NSAttributedString(string: "The Flash Poster"),
                         caption: NSAttributedString(string: "Season 3"),
                         credit: NSAttributedString(string: "Vignette"),
                         url: URL(string: "https://goo.gl/T4oZdY")!),
            ExamplePhoto(title: NSAttributedString(string: "The Flash and Savitar"),
                         caption: NSAttributedString(string: "Season 3"),
                         credit: NSAttributedString(string: "Screen Rant"),
                         url: URL(string: "https://goo.gl/pYeJ4H")!),
            ExamplePhoto(title: NSAttributedString(string: "The Flash: Rebirth"),
                         caption: NSAttributedString(string: "Comic Book"),
                         credit: NSAttributedString(string: "DC Comics"),
                         url: URL(string: "https://goo.gl/9wgyAo")!),
            ExamplePhoto(title: NSAttributedString(string: "The Flash has a cute smile"),
                         caption: nil,
                         credit: NSAttributedString(string: "Giphy"),
                         url: URL(string: "https://media.giphy.com/media/IOEcl8A8iLIUo/giphy.gif")!)
        ]
        let photosViewController = PhotosViewController(photos: photos, delegate: self)
        self.window?.rootViewController = photosViewController
        self.window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


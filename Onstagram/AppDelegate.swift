//
//  AppDelegate.swift
//  Onstagram
//
//  Copyright © 2018 Group59. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.backgroundColor = .white
        window?.rootViewController = MainTabBarController()
        return true
    }

}

